# codex-ide.nvim design

## Problem

`claudecode.nvim` lets Claude Code CLI see the file/selection currently open in
Neovim, automatically, via a local WebSocket + lockfile protocol that Claude
Code's IDE integration speaks. OpenAI's Codex CLI has an equivalent feature
(`/ide` inside the Codex TUI), but no existing Neovim plugin correctly
implements the *current* protocol Codex actually speaks:

- `johnseth97/codex.nvim` (currently installed) is a bare terminal wrapper
  around the real `codex` binary. It provides no IDE context at all.
- `ishiooon/codex.nvim` claims IDE integration but was verified empirically
  (this session) to be non-functional: it implements Claude Code's lockfile +
  WebSocket scheme with the env vars renamed (`CLAUDE_CODE_SSE_PORT` →
  `CODEX_CODE_SSE_PORT`), but those env vars do not exist anywhere in the
  `openai/codex` source. Running the real Codex TUI's `/ide` command against
  it produces: `IDE context could not be enabled. Open this project in VS
  Code or Cursor with the Codex extension active.` — the exact "no client
  found" hint string from Codex's own source, confirming it never connects.

Goal: build a Neovim plugin, `codex-ide.nvim`, that correctly implements
Codex's real local IDE protocol so that `/ide` inside a real `codex` TUI
(kept running exactly as today, in the existing `johnseth97/codex.nvim`
right-side terminal panel) picks up the active file, cursor position, visual
selection, and open tabs from Neovim — matching what `claudecode.nvim`
already does for Claude Code.

## Confirmed protocol facts

Two independent sources agree on the protocol shape (this session
cross-checked both):

1. `openai/codex` Rust source (`codex-rs/tui/src/ide_context.rs` and
   `ide_context/ipc.rs`) — read directly from the currently-installed
   `codex` v0.144.5.
2. `jclem/dotfiles`'s vendored `codex.nvim` (`doc/protocol.md`) — reverse
   engineered from the official VS Code extension's `.vsix`. No LICENSE file
   is present in that repo, so **only the protocol documentation is used as
   reference; no code is copied.**

Frame format: one binary frame per message —
`uint32_le payload_byte_length` followed by the UTF-8 JSON payload. Max frame
size 256 MiB. Zero-length frames are invalid.

Message envelope (from jclem's reverse-engineering; consistent with the
request/response shapes seen in the Rust source):

```jsonc
// request
{ "type": "request", "requestId": "uuid", "sourceClientId": "id",
  "version": 1, "method": "ide-context", "params": {},
  "targetClientId": "optional", "timeoutMs": 5000 }

// response
{ "type": "response", "requestId": "uuid", "resultType": "success",
  "method": "ide-context", "handledByClientId": "id", "result": { ... } }

// error response
{ "type": "response", "requestId": "uuid", "resultType": "error",
  "error": "no-client-found" }

// broadcast
{ "type": "broadcast", "method": "client-status-changed",
  "sourceClientId": "id", "version": 1, "params": {} }
```

Every client first sends an `initialize` request
(`params.clientType = "neovim"`); the router assigns and returns a
`clientId`.

Discovery: when a request has no `targetClientId`, the router broadcasts a
`client-discovery-request` (wrapping the original request) to all registered
clients; each replies `{ "canHandle": true|false }`; the router forwards the
real request to the first client that said yes.

`ide-context` request carries `{ "workspaceRoot": "/absolute/path" }`. A
client should only claim it can handle a request whose `workspaceRoot` is
inside one of its own workspace folders. Response shape:

```jsonc
{
  "ideContext": {
    "activeFile": {
      "label": "init.lua", "path": "lua/plugin/init.lua",
      "fsPath": "/absolute/project/lua/plugin/init.lua",
      "selection": {
        "start": { "line": 10, "character": 2 },
        "end": { "line": 12, "character": 8 },
        "anchor": { "line": 10, "character": 2 },
        "active": { "line": 12, "character": 8 }
      },
      "activeSelectionContent": "selected text",
      "selections": [ { "start": {...}, "end": {...} } ]
    },
    "openTabs": [
      { "label": "init.lua", "path": "lua/plugin/init.lua",
        "fsPath": "/absolute/project/lua/plugin/init.lua" }
    ]
  }
}
```

Positions are zero-based. `activeSelectionContent` is empty string when there
is no active visual selection. Cap selected text at 200,000 bytes (matches
both reference implementations).

**Socket path is unresolved between the two sources** and must be settled
empirically during implementation (see Open Questions):

- Rust source: primary `~/.codex/ipc/ipc.sock` (via `codex_home`), falling
  back to legacy `${TMPDIR}/codex-ipc/ipc-${uid}.sock` (or `ipc.sock` /
  `ipc-0.sock` if uid is 0).
- jclem's doc: only documents `${TMPDIR}/codex-ipc/ipc-${uid}.sock`.

Decision: **bind/connect on both paths independently** (see Architecture).
This is strictly additive (one extra listener) and removes the need to bet
on which path the currently-installed Codex build actually dials first.

Unlike Claude Code's protocol, `ide-context` is **pull-only**: Codex asks for
a snapshot when needed (`/ide`, and possibly per-turn — unconfirmed); there
is no requirement to proactively push selection-changed events the way
`claudecode.nvim`'s `selection.lua` does. This significantly simplifies the
Neovim-side implementation: context is computed on demand, not tracked
continuously.

## Multi-instance requirement

The user runs multiple Neovim instances against different projects
simultaneously. A Unix domain socket at a fixed path can only be bound by one
process. Naively, only one Neovim instance could ever answer `/ide` — wrong
for this workflow, and each instance's `/ide` request needs to resolve to
*that instance's* buffers, independently.

Codex's own discovery mechanism (`client-discovery-request` /
`client-discovery-response`, routed via a hub) is designed for exactly this:
multiple simultaneous IDE windows, each answering only for its own
workspace. `codex-ide.nvim` adopts a **router/client** pattern per socket
path:

- The first Neovim instance to successfully bind a given socket path becomes
  that path's **router**: it accepts client connections, handles
  `initialize`, runs discovery broadcasts, and forwards the winning
  client's response back to Codex. It also participates as an implicit
  client for its own workspace.
- Every subsequent Neovim instance that finds the path already bound
  connects as a **client**: sends `initialize`, and thereafter answers
  `client-discovery-request` broadcasts by checking whether the requested
  `workspaceRoot` matches its own workspace (cwd, open buffer paths, or LSP
  workspace folders), replying `canHandle`. If selected, it computes its own
  `context.lua` snapshot and returns it.
- If a client's connection attempt fails outright (socket file present but
  nothing answering — a crashed former router), it deletes the stale socket
  file and promotes itself to router.

This makes per-instance file context fully independent: each Neovim only
ever reports on its own buffers, and the router is just a dumb switch keyed
on `workspaceRoot`.

## Architecture

```
codex-ide.nvim/
  lua/codex-ide/
    init.lua     -- setup(), :CodexIdeStart/:CodexIdeStop/:CodexIdeStatus,
                    hooks into johnseth97/codex.nvim's :Codex/:CodexToggle
    role.lua      -- decide router vs client per socket path; stale-socket
                    takeover on failed connect
    router.lua     -- client registry, discovery broadcast/collect, request
                      forwarding
    client.lua      -- initialize handshake, canHandle logic, ide-context
                       response assembly
    socket.lua        -- vim.loop.new_pipe() based connect/listen, shared by
                          router and client roles
    frame.lua           -- uint32_le-length-prefixed JSON read/write,
                            including partial-frame buffering across reads
    context.lua           -- builds activeFile/openTabs snapshot from current
                              Neovim state at request time (no background
                              tracking)
    statusline.lua          -- lualine component: router/client role + which
                                file is currently being shared
```

This mirrors `claudecode.nvim`'s module boundaries (`server/*`, `tools/*`)
but drops everything that exists only for Claude's push-based protocol
(`selection.lua`'s debounce/demotion timers) and WebSocket framing/handshake
(`server/frame.lua`, `server/handshake.lua`), since Codex's protocol needs
neither.

**Explicitly out of scope for v1** (per user decision this session):

- The LSP/MCP diagnostics/references/workspace-symbol bridge
  (`codex stdio-to-uds`, `vscodeDiagnostics`/`vscodeReferences`/
  `vscodeWorkspaceSymbols`) that jclem's plugin also implements.
- Any terminal/sidebar management. `johnseth97/codex.nvim` keeps launching
  the real `codex` TUI in the existing right-side panel exactly as
  configured today; `codex-ide.nvim` only starts/stops its background socket
  role alongside `:Codex`/`:CodexToggle`, via `init.lua` wrapping those
  commands (or `keys`/`cmd` triggers in the lazy.nvim spec — `johnseth97`
  exposes no autocmd/event hook, so wrapping the command is the integration
  point).
- The VS Code desktop-app bridge (`ping`/`content`/`highlight`/etc.) — not
  relevant to a CLI-only workflow.

## workspaceRoot matching

A client claims `canHandle: true` for a request's `workspaceRoot` if any of:

1. `vim.loop.cwd()` equals or is a parent of `workspaceRoot` (or vice versa)
2. Any listed buffer's file path is inside `workspaceRoot`
3. Any active LSP client's workspace folder is inside `workspaceRoot`

## Error handling

- Stale socket file (router process died without cleanup): client's connect
  attempt fails → delete the file → retry bind as router.
- Bind race (two instances start within the same tick): the loser's bind
  fails → falls through to the client connect path already implemented, no
  special-casing needed.
- Frame parse errors: log and drop the malformed frame; do not crash the
  router/client loop.
- Codex not finding any client (empty registry, or no one claims the
  workspaceRoot): router replies `{"type":"response","resultType":"error","error":"no-client-found"}`,
  same as Codex's own hint expects — this is the existing graceful failure
  path, not a bug to "fix" further.

## Status indicator

A small `lualine` component (`statusline.lua`) shows this Neovim instance's
current role (`router`/`client`/`off`) and, when it last answered an
`ide-context` request, which file it reported. This is purely local
visibility — Codex's own TUI is expected to render the connected file/
selection itself once `/ide` succeeds (that rendering is Codex's client-side
UI, not something this plugin needs to build).

## Testing / verification

Manual, empirical, matching the methodology already validated this session:

1. Single-instance: headless Neovim opens `:Codex`, accepts the Codex trust
   prompt, sends `/ide`, and the transcript must show real file/selection
   context instead of the `"IDE context could not be enabled"` failure
   string.
2. Multi-instance: two headless Neovim instances with different `cwd`s both
   running `:CodexIdeStart`. Verify (a) exactly one becomes router, (b) both
   register successfully as router+client, (c) a `/ide` request whose
   `workspaceRoot` matches instance A's cwd is answered by A's buffers, and
   a request matching B's cwd is answered by B's — not swapped.
3. Router failover: kill the router instance, confirm the surviving client
   detects the dead socket and promotes itself without user intervention.

No unit test framework is being introduced for v1; correctness is
demonstrated via the scripted headless-Neovim + real `codex` binary probes
used throughout this session (see this session's `test_ide_probe3.lua`
approach: open the terminal, drive the real TUI via `chansend`, snapshot the
terminal buffer, assert on the rendered text).

## Open questions (to resolve during implementation, not blocking this spec)

1. Which socket path(s) does the installed `codex` v0.144.5 actually dial
   first in practice? Confirm empirically once the router is implemented
   (bind both, log which one receives the real connection).
2. Does Codex refresh `ide-context` automatically per conversation turn, or
   strictly only on explicit `/ide`? Affects nothing about this plugin's
   implementation (it's pull-only either way) but worth confirming for the
   user's mental model.
3. Repo location: this will live in its own standalone git repo (not
   vendored into the dotfiles nvim config), per the "independent plugin"
   decision — created locally as part of implementation (e.g. under
   `~/projects/codex-ide.nvim`); whether/when to push it to GitHub is a
   separate decision left to the user after it works.

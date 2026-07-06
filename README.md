# .dotfiles

Personal macOS dotfiles, managed as a **bare git repo** with `$HOME` as the
work tree (the ["bare repo" pattern](https://www.atlassian.com/git/tutorials/dotfiles)).
There is no separate `~/dotfiles` checkout directory — the repo tracks
selected files directly inside `$HOME`, and everything else in `$HOME` is
ignored by default.

## How it works

- Bare repo lives at `~/.myconf` (git-dir), work tree is `$HOME`.
- `~/.zshrc` defines two aliases that wrap plain `git`/`lazygit` with those
  two flags baked in — these are the only way this repo should be operated,
  never plain `git` inside `$HOME`:
  ```sh
  alias dotgit='/usr/bin/git --git-dir=$HOME/.myconf --work-tree=$HOME'
  alias dotlazy='lazygit --git-dir=$HOME/.myconf --work-tree=$HOME'
  ```
- `status.showUntrackedFiles` is set to `no` locally, so `dotgit status` only
  ever shows changes to files that are already tracked. New files must be
  added explicitly with `dotgit add <path>` — nothing in `$HOME` gets picked
  up by accident.

## What's tracked

Only specific files/dirs are added to the repo, e.g.:
- `.zshrc`, `.tmux.conf`, `.ideavimrc`
- `.config/nvim/` (Neovim config, plugins managed via lazy.nvim in
  `lua/brad/plugins.lua`)
- `.config/karabiner/`, `.config/lazygit/`
- `Library/Application Support/Code/User/` (VS Code settings/keybindings)

Run `dotgit ls-files` for the authoritative current list.

**Intentionally not tracked**: editor-specific configs for tools no longer
in use get removed from tracking (not deleted from disk) when they're
replaced — e.g. LunarVim, yabai/skhd/aerospace (tiling is now handled by
Raycast). Cursor's settings are also untracked since they change often and
aren't meant to sync.

## Setup on a new machine

Prerequisites this config assumes are already installed: `zsh` +
[oh-my-zsh](https://ohmyz.sh/), [Homebrew](https://brew.sh),
[tmux](https://github.com/tmux/tmux) + [tpm](https://github.com/tmux-plugins/tpm),
[lazygit](https://github.com/jesseduffield/lazygit), Neovim,
[powerlevel10k](https://github.com/romkatv/powerlevel10k).

```sh
git clone --bare git@github.com:leejh903/.dotfiles.git $HOME/.myconf
alias dotgit='/usr/bin/git --git-dir=$HOME/.myconf --work-tree=$HOME'

# back up anything that would collide with tracked files before checkout
mkdir -p ~/.dotfiles-backup
dotgit checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | \
  xargs -I{} mv {} ~/.dotfiles-backup/{} 2>/dev/null

dotgit checkout
dotgit config --local status.showUntrackedFiles no
```

After checkout:
1. Add the `dotgit`/`dotlazy` aliases to `.zshrc` if not already present
   (they're tracked, so a fresh checkout brings them in automatically).
2. Install tmux plugins: open tmux, press `prefix + I` (capital i) to fetch
   plugins via tpm.
3. `GITHUB_PERSONAL_ACCESS_TOKEN` in `.zshrc` is read from the macOS Keychain
   at shell startup (`security find-generic-password ...`) — it is **not**
   stored in this repo. On a new Mac, add the token to Keychain first:
   ```sh
   security add-generic-password -a "$USER" -s GITHUB_PERSONAL_ACCESS_TOKEN -w <token>
   ```
   On non-macOS machines this line will just no-op (empty token).

## Day-to-day usage

```sh
dotgit status          # see what's changed in tracked files
dotgit add <path>       # stage a change (or start tracking a new file)
dotgit commit -m "..."
dotgit push
dotlazy                 # same repo/worktree, via lazygit's TUI
```

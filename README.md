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

### 1. Install prerequisites

```sh
# Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Once Homebrew and the repo above (which includes `Brewfile`) are in place:

```sh
brew bundle --file=Brewfile
```

`Brewfile` installs: git, tmux, lazygit, neovim, node, ripgrep, fd (all used
by the nvim/tmux config), `dark-notify` (switches the tmux Catppuccin theme
with macOS light/dark mode), and the Meslo Nerd Font p10k needs for its
prompt glyphs.

Karabiner-Elements is a separate `.app` (not a brew formula) — install it
manually from https://karabiner-elements.pqrs.org if you want the tracked
`.config/karabiner/` mappings to apply.

### 2. Clone and check out the dotfiles

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

### 3. Finish setup

1. Restart the shell so `.zshrc` (with the `dotgit`/`dotlazy` aliases,
   already brought in by the checkout) is picked up.
2. Install tmux plugins: open tmux, press `prefix + I` (capital i) to fetch
   plugins via tpm.
3. Open nvim once — `lazy.nvim` bootstraps itself and installs plugins from
   `lua/brad/plugins.lua` on first launch; `:Mason` installs LSP servers.
4. `GITHUB_PERSONAL_ACCESS_TOKEN` in `.zshrc` is read from the macOS Keychain
   at shell startup (`security find-generic-password ...`) — it is **not**
   stored in this repo. On a new Mac, add the token to Keychain first:
   ```sh
   security add-generic-password -a "$USER" -s GITHUB_PERSONAL_ACCESS_TOKEN -w <token>
   ```
   On non-macOS machines this line will just no-op (empty token).
5. `.zshrc` sources completions for `openclaw`, a personal CLI tool that
   isn't part of this public setup. The line is guarded with a file-exists
   check, so it's a no-op if you don't have `openclaw` installed.

## Day-to-day usage

```sh
dotgit status          # see what's changed in tracked files
dotgit add <path>       # stage a change (or start tracking a new file)
dotgit commit -m "..."
dotgit push
dotlazy                 # same repo/worktree, via lazygit's TUI
```

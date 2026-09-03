# Dotfiles Config

This is all my dotfiles, current it includes settings for 
1. Neovim
1. Kitty
1. Wezterm
1. Zshrc
1. Oh My Zsh
1. Starship
1. Bashrc
1. Aerospace
1. MISE

## General Setup

The current setup is geared towards MacOS since this is the main OS I develop on.

### Package Manager

The package manager used is brew. Following the [install instructions](https://brew.sh) to install.

### Linking config / dot files

We will be using `stow` to manage sym-linking all the dotfiles to the right place by using the HOME directory as the base reference.

To install stow run
```
brew install stow
```

After you install `stow`, run the following commands to use stow to setup the symlink for different programs
```
stow -S --dotfiles -t $HOME nvim
```
You can replace the `nvim` argument with any of the subfolders. It would symlink config files to the correct locations. 

### Unlinking config / dot files

You can run the following command to remove symlink created by `stow`
```
stow -D --dotfiles -t $HOME nvim
```
Just like the setup, you can replace the `nvim` argument with any of the already setup subfolders to remove symlinks created to the subfolders.

### fff-pick

`fff-pick` is not a stow package -- it is a small Rust binary that puts the
[fff](https://github.com/dmtrKovalenko/fff) engine behind a shell file picker,
sharing its frecency database with `fff.nvim`. It is **parked**: `CTRL-T` in zsh
is still fzf. Kept in working order in case it is worth revisiting.

See [fff-pick/README.md](fff-pick/README.md) for how fff is actually
architected (no daemon, index per process), the measured scan costs that led to
parking it, and how to re-enable the `CTRL-T` binding.

### Claude Code plugins

`claude-plugins/` is not a stow package -- it holds Claude Code plugins, and this
repo doubles as a plugin marketplace (`.claude-plugin/marketplace.json`).

- **claude-inline-comment-iteration** -- `code-iterate` / `doc-iterate` skills that
  resolve `cc:` / `cc?` / `cc!` inline feedback markers left in source comments and
  Markdown notes. Pairs with the `cc-*` nvim snippets in
  `nvim/dot-config/nvim/snippets/`.

Install:
```
claude plugin marketplace add peopleskai/dotfiles
claude plugin install claude-inline-comment-iteration@peopleskai-dotfiles
```
See [claude-plugins/claude-inline-comment-iteration/README.md](claude-plugins/claude-inline-comment-iteration/README.md).

## Additional Setup for specific programs

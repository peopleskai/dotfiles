# Dotfiles Config

This is all my dotfiles, current it includes settings for 
1. Neovim
1. Kitty
1. Zshrc
1. Bashrc

## Setup

After you clone the repo, run the following command to use stow to setup the symlink farm for neovim.
```
stow -S --dotfiles -t $HOME nvim
```

The same command can be runned for the other settings by replacing `nvim`.

## Clean up

You can run the following command to remove the symlink farm for a specific setting
```
stow -D --dotfiles -t $HOME nvim
```

The same command can be runned for the other settings by replacing `nvim`.

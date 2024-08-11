# Zsh Setup

The current zsh config depends on 
1. [On My Zsh](https://ohmyz.sh) - The plugin framework currently used
1. [Starship](https://starship.rs) - for custom prompt theme
1. [mise](https://mise.jdx.dev) - for dev tools
1. [zoxide](https://github.com/ajeetdsouza/zoxide) - a better `cd`
1. [eza](https://eza.rocks) - a better `ls`
1. [bat](https://github.com/sharkdp/bat) - a better `cat`
1. [nvim](https://neovim.io) - my editor of choice
1. [fzf](https://github.com/junegunn/fzf) - my fuzy finder of choice

## Installation

As listed above, the current zsh configuration has a bunch of dependencies, lets first install all the programs, then we work on configuring the installed programs.

To install the dependencies run the following brew instlal command.
```
brew install startship mise zoxide eza bat neovim fzf 
```

After installing the dependencies, you will need to use the `stow` command found [here](../README.md) to symlink configurations for
1. starship
1. mise
1. nvim

Finally, following additional setup instructions for the following
1. [starship](../starship/INSTRUCTIONS.md)
1. [mise](../mise/INSTRUCTIONS.md)
1. [nvim](../nvim/INSTRUCTIONS.md)

Starship requires additional manual setup, you will need to setup the starship config using `stow` and also following [addtional setup instructions](../starship/INSTRUCTIONS.md).

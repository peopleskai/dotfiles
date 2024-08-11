# Neovim Setup

The current nvim setup uses [lazy.nvim](https://lazy.folke.io) as the plugin manager. `lazy` will auto install when nvim first starts up, but we still need to manually make sure all the plugins are installed correctly and external programs such as LSPs & formatters are installed with Mason as well.

# Installation

To install nvim, run the following

```
brew install neovim
```

All plugins and external programs should be installed automatically when nvim first starts. If it doesn't happen the following are manual steps to install them.

To install all the plugins, run the following cmd to start `lazy`.

```
:Lazy
```

Once the `lazy` plugin manager is start, go to `(I)nstall` tab and install all the plugins.

Once all the plugins are installed, you would have to use `Mason` to install all the external programs used. To start Mason, run the following cmd

```
:Mason
```

Then make sure the following programs are installed with Mason

1. gersemi
1. prettier
1. clang-format
1. bash-language-server bashls
1. clangd
1. cmake-language-server cmake
1. cmakelang
1. dart-debug-adapter
1. json-lsp jsonls
1. lua-language-server lua_ls
1. marksman
1. pyright
1. rust-analyzer rust_analyzer
1. shfmt
1. stylua
1. taplo

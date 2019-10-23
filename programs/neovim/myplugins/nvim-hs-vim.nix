{ pkgs, ... }:
{
  description = ''
    This plugin contains functions to help start a nvim-hs plugin as a separate process.

    More detailed help is available via :help nvim-hs.txt once this plugin is installed.

    https://github.com/neovimhaskell/nvim-hs.vim
  '';
  pkg = pkgs.vimPlugins.nvim-hs-vim;
  extraConfig = [
    # nvim-hs.vim is stack-only as of 10-23-2019
    "let g:nvimhsPluginStarter=nvimhs#stack#pluginstarter()"
  ];
}


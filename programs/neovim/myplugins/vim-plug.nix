{ pkgs, lib, pluginBuilder, ... }:
let
  notPython = pkgs.writeScript "notPython" ''
    #!${pkgs.stdenv.shell}
    shift
    shift
    shift
    wakatime "$@"
  '';
in
{
  description = "";
  pkg = pkgs.vimPlugins.vim-plug;
  extraConfig = [
    # Specify a directory for plugins
    # - For Neovim: stdpath('data') . '/plugged'
    # - Avoid using standard Vim directory names like 'plugin'
    "call plug#begin('${builtins.getEnv "HOME"}/.config/nvim/plugged')"
    "Plug 'wakatime/vim-wakatime'"
    "Plug 'neovimhaskell/nvim-hs.vim'"
    "Plug 'lervag/vimtex'"
    "call plug#end()"
    "let g:wakatime_PythonBinary = '${notPython}'"
    "let g:nvimhsPluginStarter=nvimhs#stack#pluginstarter()"
    "let g:vimtex_compiler_progname = 'nvr'"
  ];
}


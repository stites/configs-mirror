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
    "call plug#end()"
    "let g:wakatime_PythonBinary = '${notPython}'"
  ];
}


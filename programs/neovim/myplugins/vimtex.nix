{ pkgs, lib, ... }:
{
  description = "tex support";
  pkg = pkgs.vimPlugins.vimtex;
  extraConfig = [
    # use neovim's async process to trigger latex
    "let g:vimtex_compiler_progname = 'nvr'"
  ];
}

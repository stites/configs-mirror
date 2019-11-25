{ pkgs, lib, ... }:
{
  description = "";
  pkg = pkgs.vimPlugins.vim-gutentags;
  extraConfig = [
    "set statusline+=%{gutentags#statusline()}"
  ];
}


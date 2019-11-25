{ pkgs, ... }:
{
  pkg = pkgs.vimPlugins.deoplete-nvim;
  extraConfig = [
    "let g:deoplete#enable_at_startup = 1"
  ];
}

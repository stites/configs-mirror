{ pkgs, ... }:
{
  pkg = pkgs.vimPlugins.coc-vimtex;
  dependencies = [
    ../vimtex.nix
  ];
}

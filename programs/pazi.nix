{ pkgs, ... }:
{
  programs.pazi = {
    enable = true;
    enableBashIntegration = true;
  };
}

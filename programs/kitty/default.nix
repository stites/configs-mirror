{ pkgs, ... }:
{
  xdg.configFile."kitty/kitty.conf".source = "${builtins.getEnv "HOME"}/git/configs/programs/kitty/kitty.conf";
}

{ pkgs, lib, pluginBuilder, ... }:
let
  notPython = pkgs.writeScript "notPython" ''
    #!${pkgs.stdenv.shell}
    shift
    shift
    shift
    wakatime "$@"
  '';
  wakaconfig = lib.generators.toINI {} {
    settings = {
      debug = false;
      # api_key = "____________________________________"; # remove this
      hide_file_names = false;
      hide_project_names = false;
      # hide_branch_names =
      exclude = ''
        ^COMMIT_EDITMSG$
        ^TAG_EDITMSG$
        ^/var/(?!www/).*
        ^/etc/
      '';
      include = ''
        .*
      '';
      include_only_with_project_file = false;
      status_bar_icon = true;
      status_bar_coding_activity = true;
      # offline = true;
      # proxy = "https://user:pass@localhost:8080";
      # no_ssl_verify = false;
      # ssl_certs_file =
      # timeout = 30;
      # hostname = machinename
    };
    # projectmap = {
    #   "projects/foo" = "new project name";
    #   "^/home/user/projects/bar(\\d+)/" = "project{0}";
    # };
    git = {
      disable_submodules = false;
    };
  };
in
{
  description = "";
  pkg = (pluginBuilder {
    name = "vim-wakatime";
    homepage = https://www.github.com/wakatime/vim-wakatime;
    rev = "29d14cca6593a4809a31cfc3565a366d87426daf";
  }).overrideAttrs(old: {
    configurePhase = ''
      export WAKATIME_HOME="$HOME/.config/wakatime"
    '';
  });
  extraConfig = [
    "let g:wakatime_PythonBinary = '${notPython}'"
    # "let g:wakatime_PythonBinary = 'export WAKATIME_HOME=/home/stites/; ${pkgs.python}'"
  ];
}


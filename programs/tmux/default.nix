{ pkgs, lib, ... }:

with pkgs;

{
  programs.tmux = {
    enable = true;
    tmuxp.enable = false;
    aggressiveResize = true;
    sensibleOnTop = true;
    baseIndex = 1;
    escapeTime = 0;

    plugins = [
      # tmuxPlugins.battery
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-dir '${builtins.getEnv "HOME"}/.tmux/resurrect'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];
    keyMode = "vi";
    historyLimit = 500000;
    secureSocket = false;
    customPaneNavigationAndResize = true;
    newSession = true;
    resizeAmount = 5;
    shortcut = "b";
    terminal = "screen-256color";
    extraConfig = let
      inherit (pkgs.callPackage ./compile.nix {})
        compile quote compile-block expand-with-default-flags;

      unbind-key = key: # alias to unbind
        "unbind-key ${key}";

      bind-key = key: to: { repeatable ? false, table ? null, args ? []}: with lib.strings; # alias to bind
        let
          opt = lib.optionalString;
          _flags =
            if repeatable || table == "root"
            then concatStrings [
              "-" (opt repeatable "r") (opt (table == "root") "n")
            ] + opt (table != null && table != "root") " -T ${table}"
            else "";
        in "bind-key ${_flags} ${key} ${to} ${concatStringsSep " " args}";

    in with lib.strings; compile [
      # make sure new windows start from older ones
      (bind-key  "c"   "new-window"   {args = ["-c"      (quote "#{pane_current_path}")];})
      (bind-key  "%"   "split-window" {args = ["-c" "-h" (quote "#{pane_current_path}")];})
      (bind-key "'\"'" "split-window" {args = ["-c" "-v" (quote "#{pane_current_path}")];})

      # Sync panes
      (bind-key "y" "setw" {args = ["synchronize-panes"];})

      # ++++++++++++++++++++++++++++ #
      #      use vi copy/paste       #
      # ++++++++++++++++++++++++++++ #
      # see: http://bit.ly/1LuQQ8h
      (unbind-key "[")
      (bind-key "Escape" "copy-mode" {})
      (unbind-key "p")

      # https://unix.stackexchange.com/questions/67673/copy-paste-text-selections-between-tmux-and-the-clipboard#72340
      # https://unix.stackexchange.com/questions/131011/use-system-clipboard-in-vi-copy-mode-in-tmux
      (bind-key "p" "run" { args = [("'tmux set-buffer \"$(xclip -o)\"; tmux paste-buffer'")];})

      (let
        bind-copy-mode-key = k: args:
          bind-key "'${k}'" "send" { table = "copy-mode-vi"; args = ["-X"] ++ args; };
      in [
        (bind-copy-mode-key "'v'" ["begin-selection"])
        (bind-copy-mode-key "'V'" ["select-line"])
        (bind-copy-mode-key "'r'" ["rectangle-toggle"])
        (bind-copy-mode-key "'y'" ["copy-pipe-and-cancel" (quote "xclip -i -sel p -f | xclip -i -sel c") ])
      ])

      # move x clipboard into tmux paste buffer
      # move tmux copy buffer into x clipboard
      (bind-key "C-y" "run" { args = [(quote "tmux save-buffer - | xclip -i")]; })

      # Smart pane switching with awareness of vim splits
      (let
        is_vim = "is_vim";
        bind-direction = key: dir:
          bind-key key "if-shell" {
            table = "root";
            args = [ ''"$$${is_vim}" "send-keys ${key}" "select-pane -${dir}"''];
          };
      in
      [ ''
        ${is_vim}='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
        ''
        (bind-direction "C-j" "D")
        (bind-direction "C-k" "U")
        (bind-direction "C-h" "L")
        (bind-direction "C-l" "l")
      ])

      # Restoring Clear Screen (C-l) <<< This is blocking the above
      (let restore-key = k: bind-key k "send-keys" { args = [("'"+k+"'")]; };
      in
      [ (restore-key "C-l")
        (restore-key "C-k")
        (restore-key "C-u")
      ])

      # Start GoTTY in a new window with C-t
      # bind-key C-t new-window "gotty tmux attach -t `tmux display -p '#S'`"

      (compile-block {
        options = expand-with-default-flags "g" {
          # Fixes for ssh-agent
          update-environment = quote (concatStringsSep " " [
            "SSH_ASKPASS"
            "SSH_AUTH_SOCK"
            "SSH_AGENT_PID"
            "SSH_CONNECTION"
          ]);
          mouse = true;          # Enable mouse mode (tmux 2.1 and above)
          allow-rename = false;  # Stop renaming windows automatically
          renumber-windows=true; # But reorder windows automatically

          # +++++++++++++++++++++++++++++ #
          # set titles on and use un@host #
          # +++++++++++++++++++++++++++++ #
          terminal-overrides = quote (concatStringsSep "," [
            "xterm*:XT:smcup@:rmcup@"
            "screen*:cvvis=\\E[34l\\E[?25h"
          ]);
          set-titles-string = quote "#T";

          # loud or quiet?
          visual-activity=false;
          visual-bell=false;
          visual-silence=false;
          bell-action=null; # set-option -g bell-action none

          pane = {
            # border.style = {fg="black";};
            # border.style = {fg="colour196"; bg="colour238";};
            border.style = {fg="colour238"; bg="colour196";};
            # active-border.style = {fg="brightred";};
            # active-border.style = {fg="colour196"; bg="colour238";};
            active-border.style = {fg="colour51"; bg="colour236";};
          };

          ## Status bar design
          status = {
            justify="left";
            left="''''"; # Info on left (I don't have a session display for now)
            left-length=20;
            position="bottom";
            right = quote (concatStringsSep " | " [
              # functions come from 'tmux-plugins/tmux-battery'
              "#{battery_icon} #{battery_percentage}"
              ("Remaining: #{battery_remain}"
              +"#[fg=colour233,bg=colour241,bold] %a %h-%d #[fg=colour233,bg=colour245,bold] %H:%M "
              )
            ]);
            right-length = 50;
            # style = {bg="blue";fg="black";})
            # style = {bg="default"; fg="colour12";};
            style = {fg="colour137"; bg="colour234"; attrs=["dim"];};
          };

          message = {
            # style = {fg="black"; bg="yellow";};
            style = {fg="colour232";bg="colour166";attrs=["bold"];};
            command.style = {fg="blue"; bg="black";};
          };
        };

        ######################
        ### DESIGN CHANGES ###
        ######################
        # taken from: http://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/
        window-options = expand-with-default-flags "g" {
          monitor-activity=false;
          clock-mode-colour="colour135";
          mode.style = {fg="colour196"; bg="colour238";attrs=["bold"];};

          window-status = {
            # format= quote "#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W ";
            format = quote "#I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F ";
            # style = {bg="green";fg="black";attrs=["reverse"];};
            style = {fg="colour138"; bg="colour235";attrs=["none"];};
            bell.style = {fg="colour255"; bg="colour1";attrs=["bold"];};
            current = {
              # format = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
              format = quote " #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F ";
              # style = {bg="colour0";fg="colour11";attrs=["dim"];};
              style = {fg="colour81"; bg="colour238";attrs=["bold"];};
            };
          };
        };
      })
    ];
  };
}

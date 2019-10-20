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
    in with lib.strings; compile [
      # make sure new windows start from older ones
      ''
      bind c   new-window      -c "#{pane_current_path}"
      bind %   split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      ''

      # Sync panes
      "bind y setw synchronize-panes"

      # ++++++++++++++++++++++++++++ #
      #      use vi copy/paste       #
      # ++++++++++++++++++++++++++++ #
      # see: http://bit.ly/1LuQQ8h
      ''
      unbind [
      bind Escape copy-mode
      unbind p
      ''
      # https://unix.stackexchange.com/questions/67673/copy-paste-text-selections-between-tmux-and-the-clipboard#72340
      # https://unix.stackexchange.com/questions/131011/use-system-clipboard-in-vi-copy-mode-in-tmux
      ''
      bind p run "tmux set-buffer \"$(xclip -o)\"; tmux paste-buffer"
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'V' send -X select-line
      bind-key -T copy-mode-vi 'r' send -X rectangle-toggle
      bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "xclip -i -sel p -f | xclip -i -sel c"
      ''
      # bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "xclip -in -selection clipboard"

      # move x clipboard into tmux paste buffer
      # move tmux copy buffer into x clipboard
      ''bind C-y run "tmux save-buffer - | xclip -i"''

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

      #### ADDED TO HOME_MANAGER
      #### # set -g default-terminal "screen-256color"

      ########################################################

      # Smart pane switching with awareness of vim splits
      ''
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"

      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -l"
      ''

      # Restoring Clear Screen (C-l) <<< This is blocking the above
      ''
      bind C-l send-keys 'C-l'
      bind C-k send-keys 'C-k'
      bind C-u send-keys 'C-u'
      ''

      # Start GoTTY in a new window with C-t
      # bind-key C-t new-window "gotty tmux attach -t `tmux display -p '#S'`"
    ];
  };
}

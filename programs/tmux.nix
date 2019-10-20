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
      compile = stuff:
        let go = s: if builtins.isString s then s else generic-args s;
        in lib.strings.concatStringsSep "\n" (map go (lib.lists.flatten stuff));

      generic-args = {
        prefix ? "",
        suffix ? "",
        flags ? null,
        cmd,
        kwargs ? {}}:
          let _flags = lib.optionalString (flags != null) "-${flags}";
              _cmd = "${prefix}${cmd}${suffix}";
              _pairs = parse-kwargs kwargs;
          in lib.strings.concatStringsSep "\n" (map (kv: "${_cmd} ${_flags} ${kv}") _pairs);

      parse-kwargs = kwargs: with builtins; with lib.attrsets; with lib.lists;
        let
          eleAsString = v:
            if isString v
            then v
            else if isBool v
              then (if v then "on" else "off")
              else if v == null then "none"
                else toString v;
          isStyles = k: v: k == "styles" && isAttrs v;
          eles   = filterAttrs (k: v: !(isStyles k v)) kwargs;
          styles = if hasAttr "styles" kwargs then getAttr "styles" kwargs else {};

          styleAsString = style: kv: "${style}-style ${smoosh-styles kv}";
          smoosh-styles = kv: concatStringsSep ","
            (  lib.optionals (hasAttr "fg" kv) ["fg=${kv.fg}"]
            ++ lib.optionals (hasAttr "bg" kv) ["bg=${kv.bg}"]
            ++ lib.optionals (hasAttr "attrs" kv && isList kv.attrs) kv.attrs);

        in mapAttrsToList (k: v: "${k} ${eleAsString v}") eles
          ++ mapAttrsToList styleAsString styles;

      # generating arguments for generic-args
      quote  = s: assert builtins.isString s; "\"${s}\"";
      set    = kwargs: {cmd="set"; inherit kwargs;};
      setw   = kwargs: let x = 1; in (set kwargs) // {suffix="w";};
      set-g  = kwargs: (set kwargs) // {flags="g";};
      setw-g = kwargs: (set kwargs) // {flags="g"; suffix="w";};
      set-styles = style: attrs:
        let askwargs = k: v: {cmd="set"; flags="g"; kwargs={"${style}-style"="${k}=${v}";};};
        in lib.attrsets.mapAttrsToList askwargs attrs;
      setw-styles = style: attrs: map (set: set // {suffix = "w";}) (set-styles style attrs);
      set-option = kwargs: set kwargs; # set is an alias to set-option
      set-option-g = kwargs: set-g kwargs; # set is an alias to set-option
    in compile [
      # make sure new windows start from older ones
      ''
      bind c   new-window      -c "#{pane_current_path}"
      bind %   split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      ''

      # Sync panes
      "bind y setw synchronize-panes"

      # Fixes for ssh-agent
      (set-g {
        update-environment=''"SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION"'';
        mouse=true; # Enable mouse mode (tmux 2.1 and above)
        allow-rename=false;    # Stop renaming windows automatically
        renumber-windows=true; # But reorder windows automatically
      })

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

      (set-styles "status" {bg="blue";fg="black";})

      # +++++++++++++++++++++++++++++ #
      # set titles on and use un@host #
      # +++++++++++++++++++++++++++++ #
      (set-g {
        terminal-overrides=''"xterm*:XT:smcup@:rmcup@"'';
        set-titles-string=''"#T"'';
      })

      ######################
      ### DESIGN CHANGES ###
      ######################
      # taken from: http://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/

      # panes
      (set-styles "pane-border" {fg="black";})
      (set-styles "pane-active-border" {fg="brightred";})

      ## Status bar design
      # status line
      (set-g {
        status-justify="left";
        styles = {status = { bg="default"; fg="colour12";};};
      })

      # messaging
      (set-g {
        styles = {
          message = {fg="black"; bg="yellow";};
          message-command = {fg="blue"; bg="black";};
        };
      })


      #window mode
      (setw-styles "mode" {bg="colour6";fg="colour0";})

      # window status
      (setw-g {
        # window-status-format=''" #F#I:#W#F "'';
        # window-status-current-format=''" #F#I:#W#F "'';
        window-status-format=''"#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "'';
        window-status-current-format=quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
        styles = {
          window-status = {bg="green";fg="black";attrs=["reverse"];};
          window-status-current = {bg="colour0";fg="colour11";attrs=["dim"];};
        };
      })

      # Info on left (I don't have a session display for now)
      (set-g {
        status-left="''''";

        # loud or quiet?
        visual-activity=false;
        visual-bell=false;
        visual-silence=false;
        bell-action=null; # set-option -g bell-action none
      })
      "set-window-option -g monitor-activity off"

      #### ADDED TO HOME_MANAGER
      #### # set -g default-terminal "screen-256color"

      # The modes {
      (setw-g {
        clock-mode-colour="colour135";
        styles = {
          mode = {fg="colour196"; bg="colour238";attrs=["bold"];};
        };
      })

      # }
      # The panes {
      # (set-styles "pane-border" {fg="colour196"; bg="colour238";})
      # (set-styles "pane-active-border" {fg="colour196"; bg="colour238";})

      (set-styles "pane-border" {fg="colour238"; bg="colour196";})
      (set-styles "pane-active-border" {fg="colour51"; bg="colour236";})

      # }
      # The statusbar {
      (set-g {
        status-position="bottom";
        status-left="''''";
        status-right="'#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '";
        status-right-length=50;
        status-left-length=20;
        styles = { status = {fg="colour137"; bg="colour234"; attrs=["dim"];}; };
      })
      (setw-g {
        window-status-format= quote "#I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F ";
        window-status-current-format = quote " #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F ";
        styles = {
          window-status = {fg="colour138"; bg="colour235";attrs=["none"];};
          window-status-bell = {fg="colour255"; bg="colour1";attrs=["bold"];};
          window-status-current = {fg="colour81"; bg="colour238";attrs=["bold"];};
        };
      })

      # }
      # The messages {
      (set-g {
        styles = { message = {fg="colour232";bg="colour166";attrs=["bold"];}; };
      })
      # }

      ########################################################
      ## functions come from 'tmux-plugins/tmux-battery'
      (set-g {
        status-right="'#{battery_icon} #{battery_percentage} | Remaining: #{battery_remain} | %a %h-%d %H:%M '";
      })

      # Smart pane switching with awareness of vim splits
      ''
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"

      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -l"
      ''

      ''
      set -ag terminal-overrides ',screen*:cvvis=\E[34l\E[?25h'
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

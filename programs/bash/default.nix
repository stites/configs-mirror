{ pkgs, lib, ... }:

let
  host = pkgs.callPackage ../../hosts { };
  colors = import ./colors.nix;
  pyenv = pkgs.callPackage ./pyenv.nix { };
  git = pkgs.callPackage ./git.nix { };
  nvm = pkgs.callPackage ./nvm.nix { };
  rbenv = pkgs.callPackage ./rbenv.nix { };
  fasd = pkgs.callPackage ./fasd.nix { };
  prompt = pkgs.callPackage ./prompt.nix { };
  nix = pkgs.callPackage ./nix.nix { };
  haskell = pkgs.callPackage ./haskell.nix { };
  functions = pkgs.callPackage ./functions.nix { };
  homedir = host.homedir;
  nix-profile = "${host.homedir}/.nix-profile/";
  secrets = import ../../secrets.nix;
  hostExtraConfig = host.bash.extraConfig;
in
{
  home.packages = [pkgs.wakatime];
  xdg.dataFile = {
    "remarkable-upload" = {
      executable = true;
      target = "../bin/remarkable-upload";
      text = ''
        #!/usr/bin/env bash
        f="$1"
        f=${ lib.concatStrings ["$" "{f//" "\\" "\\" "/\\" "\\" "\\" "\\" "}" ] }
        f=${ lib.concatStrings ["$" "{f//" "\\" ''"'' "/" "\\" "\\" "\\" ''"'' "}" ] }
        f=${ lib.concatStrings ["$" "{f//;/\\\\;}" ] }
        ${pkgs.curl}/bin/curl -w '\n' --form "file=@\"$f\"" "http://10.11.99.1/upload"
      '';
    };
    "bk" = {
      executable = true;
      target = "../bin/bk";
      text = ''
        #!/usr/bin/env bash

        FILE="$1"

        if [[ "$(printf "%s" "$FILE" | tail -c -3)" == ".bk" ]]; then
          NEWNAME="$(printf "%s" "$FILE" | rev | cut -c 4- | rev)"
          mv "$FILE" "$NEWNAME"
        else
          mv "$FILE" "$FILE.bk"
        fi
      '';
    };
  };
  home.file.".bash/empty".text = "";
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
    };
    man.enable = true;
    noti = {
      enable = true;
      # TODO: bundle this into a function call
      settings = {
        pushover = {
          apiToken = secrets.bash.pushover.apikey;
          userKey = secrets.bash.pushover.userkey;
        };
      };
    };

    htop.enable = true;
    lesspipe.enable = true;
    command-not-found.enable = true;

    bash = {
      enable = true;

      # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
      historyIgnore = [ "ls" "cd" "exit" ".." "..." "gs" "ll" "lll" ];

      # These parameters are overwritten later. See "Eternal bash history" in extraConfig
      historySize = 100000;
      historyFileSize = 200000;
      historyFile = "${homedir}/.bash/eternal_history";
      shellOptions = [
        "histappend"     # append to the history file, don't overwrite it
        "nocaseglob"     # auto corrects the case
        "checkwinsize"   # check the window size after each command and, if
                         # necessary, update the values of LINES and COLUMNS.
        "globstar"       # If set, the pattern "**" used in a pathname
                         # expansion context will match all files and zero or
                         # more directories and subdirectories.
      ];

      # These are sourced in ~/.profile and do _not_ get reloaded at exec $SHELL
      sessionVariables = {
        #IFS=$'\n\t'
        # ^^^ unofficial bash mode: https://perma.cc/UQ45-72E5
        EDITOR="nvim";
        BROWSER="firefox"; # toggle with lynx for headless servers
        PAGER="most";
        MOST_SWITCHES="-w -s"; # -s don't show excess blank lines, -w line wrap the output

        # extra exports that nix doesn't support
        HISTCONTROL="ignoredups:ignorespace:erasedups:ignoreboth";

        # potentially removable
        LC_ALL="en_US.UTF-8";
        LANG="en_US.UTF-8";

        # makes keybase usable again by correcting against
        # https://github.com/systemd/systemd/issues/5247
        XDG_RUNTIME_DIR="/run/user/$(id -u)";

        # makes zotero open pdfs
        QT_QPA_PLATFORM_PLUGIN_PATH="/run/current-system/sw/lib/qt-5.12/plugins";

        # # provide consistent interface for single-user nix
        # # see https://github.com/NixOS/nix/issues/2033
        # NIX_PATH="$NIX_PATH:${homeDir}/.nix-defexpr/channels";

        # bash automatically fetches the last command that starts with the
        # given term: E.G. you type in ‘ssh’ and press the ‘Page Up’ key and bash
        # scrolls through your history for this. Store function in .inputrc
        INPUTRC="${homedir}/.inputrc";

        # colored GCC warnings and errors
        # export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

        # Use https://github.com/rdnetto/powerline-hs
        POWERLINE_COMMAND="${homedir}/.local/bin/powerline-hs";
        POWERLINE_CONFIG_COMMAND="${nix-profile}/bin/true";

        # # make less more friendly for non-text input files, see lesspipe(1)
        # # the output of eval "$(SHELL=/bin/sh lesspipe.sh)"
        # LESSOPEN="|${nix-profile}/bin/lesspipe.sh %s"; # FIXME << do we even need this?

        # hledger stuff
        LEDGER_FILE="${homedir}/accounting/2019.journal";

        # and https://github.com/NixOS/nixpkgs/issues/44144
        CPATH=host.bash.includePath;
        C_INCLUDE_PATH=host.bash.includePath;
        CPLUS_INCLUDE_PATH=host.bash.includePath;

        LIBRARY_PATH=host.bash.libraryPath;
        TMUXIFIER="${homedir}/.tmuxifier";

        #########################################################
        #########################################################

      } // colors // pyenv.variables // prompt.variables;

      shellAliases = {
        # ===================== #
        # .bashrc functions     #
        # ===================== #
        vrc  = "vim $HOME/.bashrc";
        src  = "exec $SHELL";
        mr   = "monitors reset";
        mh   = "monitors home";
        ms   = "monitors sentenai";

        # tree with color
        tree = "tree -C";

        # dd with sync and show IO errors
        # dd="dd sync=progress conv=fsync";

        # Relative Jumps:
        "~"="cd ~ ";
        ".."="cd ..";
        "..."="cd ../..";
        "...."="cd ../../..";
        "....."="cd ../../../..";

        # == mail functions for bash == #
        neomutt="cd ~/.mail/attachments && neomutt";
        mutt="${nix-profile}/bin/neomutt";

        # tmux aliases
        # protonmail-bridge="echo 'running Desktop-Bridge --cli in \\'mail\\' tmux session' && ${nix-profile}/bin/tmux new-session -d -s mail 'Desktop-Bridge --cli'";
        ws="${nix-profile}/bin/tmux attach -t stites";
        mail="${nix-profile}/bin/tmux attach -t mail";

        # vim aliases
        vimd="${nix-profile}/bin/nvim --headless ";
        vimattach="${nix-profile}/bin/nvim --servername VIM_SERVER --remote-tab ";
        visnippets="${nix-profile}/bin/nvim ~/.config/nvim/snippets/haskell.snippets";

        # == ghci-to-bash == #
        ":q"="exit";
        ":r"="myReload";
        # == vim-to-bash == #
        ":e"="vim";

        preview="${nix-profile}/bin/fzf --preview 'bat --color \"always\" {}'";

        cat  = "${nix-profile}/bin/bat";
        less = "${nix-profile}/bin/most";
        ping = "${nix-profile}/bin/prettyping --nolegend";
        top  = "${nix-profile}/bin/htop";
        du   = "${nix-profile}/bin/ncdu --color dark -rr -x --exclude .git --exclude node_modules --exclude .stack-work --exclude dist-newstyle";
        help = "${nix-profile}/bin/tldr";
        curl = "${nix-profile}/bin/http";

        # the lss
        la   = "${nix-profile}/bin/exa";
        ls   = "${nix-profile}/bin/exa -s extension";
        l    = "${nix-profile}/bin/exa -s extension --group-directories-first -g -l";
        ll   = "${nix-profile}/bin/exa -s extension --group-directories-first -g -a -l";
        lll  = "${nix-profile}/bin/exa -s extension --group-directories-first -g -aa -l";

        # the greps
        grep="grep --color=auto";
        fgrep="fgrep --color=auto";
        egrep="egrep --color=auto";
        igrep="egrep -i --color=auto";
        vgrep="vgrep -v";

        # dictd:https://www.unixmen.com/look-dictionary-definitions-via-terminal/
        define="${nix-profile}/bin/dictd -d gcide ";
        hside="tmuxifier load-window hs";
        pyide="tmuxifier load-window py";

        # Add an "alert" alias for long running commands.  Use like so:
        #   sleep 10; alert
        # alert = "notify-send --urgency=low -i \\\"$([ $? = 0 ] && echo terminal || echo error)\\\" \\\"$(history|tail -n1|sed -e '\\''s/^\\s*[0-9]\\+\\s*//;s/[;&|]\\s*alert$//'\\'')\\\"'";


        # disabled unless we install nginx
        # "nginx.conf"="vim ~/.config/nginx/conf/nginx.conf";
        # "nginx"="nginx -p ~/.config/nginx/";
      } // git.shellAliases // haskell.shellAliases;

      initExtra = (lib.strings.concatStringsSep "\n" [
        # Eternal bash history.
        # ---------------------
        # Undocumented feature which sets the size to "unlimited".
        # http://stackoverflow.com/questions/9457233/unlimited-bash-history
        ''
        export HISTFILESIZE=
        export HISTSIZE=
        ''
        # include time and date in history
        "export HISTTIMEFORMAT=\"[%F %T] \""

        # Change the file location because certain bash sessions truncate .bash_history file upon close.
        # http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
        ''export HISTFILE="${homedir}/.bash/eternal_history";''

        "set +o vi"

        # enable programmable completion features (you don't need to enable
        # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
        # sources /etc/bash.bashrc).
        # FIXME: remove this? it's legacy from debian and ubuntu
        ''
        if ! shopt -oq posix; then
          if [ -f ${nix-profile}/etc/profile.d/bash_completion.sh ]; then
            source ${nix-profile}/etc/profile.d/bash_completion.sh
          else
            echo "warning! <nixpkgs>.bash-completion/etc/profile.d/bash_completion.sh not found. maybe garbage collection occured?"
          fi
        fi
        ''

        functions.functions
        functions.initConfig

        (if builtins.pathExists "/bin"            then "safe_path_add /bin"            else "")
        (if builtins.pathExists "/sbin"           then "safe_path_add /sbin"           else "")
        (if builtins.pathExists "/usr/bin"        then "safe_path_add /usr/bin"        else "")
        (if builtins.pathExists "/usr/sbin"       then "safe_path_add /usr/sbin"       else "")
        (if builtins.pathExists "/usr/local/bin"  then "safe_path_add /usr/local/bin"  else "")
        (if builtins.pathExists "/usr/local/sbin" then "safe_path_add /usr/local/sbin" else "")
        (if host.is.NixOS then "" else "source ${homedir}/.nix-profile/etc/profile.d/nix.sh")
        (if host.is.NixOS then "" else "source ${homedir}/.nix-profile/etc/profile.d/hm-session-vars.sh")

        # provide consistent interface for single-user nix
        # see https://github.com/NixOS/nix/issues/2033
        # FIXME: This is repeated in .profile but doesn't seem to stick
        ''export NIX_PATH="$NIX_PATH:$HOME/.nix-defexpr/channels"''

        # This breaks graphics in 19.03 if moved to 'sessionVariables'...
        # Maybe
        (if host.is.NixOS then "" else "export LD_LIBRARY_PATH=${host.bash.libraryPath}")

        git.functions

        fasd.initConfig

        haskell.functions
        haskell.initConfig

        nix.functions
        nix.initConfig

        nvm.initConfig

        pyenv.initConfig

        rbenv.initConfig

        prompt.functions
        prompt.initConfig

        # this is all rust needs
        (if builtins.pathExists "${homedir}/.cargo/bin" then ''safe_path_add "${homedir}/.cargo/bin"'' else "")

        # # ========================================== #
        # #     Silence that fucking hardware bell     #
        # # ========================================== #
        # ''
        # [[ -n "$DISPLAY" ]] && xset b off
        # ''

        # ============================================================ #
        # core aliases which must be added last -- PR for home-manager #
        # ============================================================ #
        ''
        # alias find="${nix-profile}/bin/fd"
        safe_source "${homedir}/.fonts/*.sh"
        ''

        # set up tmuxifier
        ''
        safe_path_add "$TMUXIFIER/bin"
        safe_source "$TMUXIFIER/init.sh"
        safe_source "$TMUXIFIER/completion/tmuxifier.bash"
        ''
        # Not ready for this:
        # ''
        #   safe_source "$XDG_DATA_HOME/bash-wakatime.sh"
        # ''
        ''
        export WAKATIME_HOME="$HOME/.config/wakatime"
        ''

        host.bash.extraConfig
      ]);
    };
  };
}

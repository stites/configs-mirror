{ pkgs, lib, ... }:

with builtins; with lib.strings; with lib.attrsets; with lib.lists;

rec {
  compile = stuff:
    let go = s: if builtins.isString s then s else compile-block s;
    in concatStringsSep "\n" (map go (lib.lists.flatten stuff));

  quote = s: assert builtins.isString s; "\"${s}\"";

  # =======================================================================#
  # Begin
  # =======================================================================#
  expand-with-default-flags = dflags: attrset: assert isAttrs attrset;
    let
      expandableKV = k: v:
        (k != "style" && k != "set" && k != "flags")
        && (isString v || isBool v || v == null);

      mergeFlags = flags:
        concatStringsSep "" (unique (stringToCharacters flags ++ stringToCharacters dflags));

      addFlagsTo = p:
        p // { flags = if hasAttr "flags" p then mergeFlags p.flags else dflags; };

      expandWithFlags = p:
        mapAttrs (k: v: if expandableKV k v then {set=v; flags=dflags;} else v) p;

      updateParent = path: p:
        if !isAttrs p then addFlagsTo { set = p; }
        else if last path == "style" then addFlagsTo p
        else if hasAttr "set" p then addFlagsTo (expandWithFlags p)
        else expandWithFlags p;

      go = attrset: memo: path: node:
        recursiveUpdate memo (setAttrByPath path (updateParent path node));
    in
      recurse-on-nodes go {} attrset;

  recurse-on-nodes = f: memo: attrset: assert isAttrs attrset;
    let
      prepQueue = ps: as: mapAttrsToList (k: v: { path = ps ++ [k]; val = v; }) as;
      getChildren = ps: curr: lib.optionals (isAttrs curr) (prepQueue ps (filterAttrs (k: v: isAttrs v) curr));
      recurse = memo: queue:
        let
          curr = head queue;
          rest = tail queue;
        in
          if length queue == 0
          then memo
          else recurse (f attrset memo curr.path curr.val) (rest ++ getChildren curr.path curr.val);
    in recurse memo (prepQueue [] attrset);
    # in (prepQueue [] attrset);

  val2str = v:
    if isString v
      then v
      else if isBool v
        then if v then "on" else "off"
        else if v == null then "none"
          else toString v;

  compileone = k: v:
    # error: most likely used "styles" instead of "style"
    assert !(hasSuffix "bg" k || hasSuffix "fg" k);
    # this is where the compile rules are made
    let
      isValid = hasSuffix "-style" k || hasAttr "set" v;
      smoosh-styles = v: concatStringsSep ","
        (  lib.optionals (hasAttr "fg" v) ["fg=${v.fg}"]
        ++ lib.optionals (hasAttr "bg" v) ["bg=${v.bg}"]
        ++ lib.optionals (hasAttr "attrs" v && isList v.attrs) v.attrs);

      setting = {
        "${k}" =
          ( if hasSuffix "-style" k
            then { set = smoosh-styles v; }
            else if hasAttr "set" v
              then { set = val2str v.set; }
              else if isBool v || isString v || v == null
                then { set = val2str v; }
                else {}
          ) // optionalAttrs (hasAttr "flags" v) { flags = v.flags; };
       };
    in lib.optionalAttrs isValid setting;

  compile-attrs = attrset: assert isAttrs attrset;
    let
      prepQueue = p: as: mapAttrsToList (k: v: {
        key = if p == "" then k else p + "-" + k;
        val = v;
      }) as;

      getChildren = p: curr: prepQueue p (filterAttrs (k: v: isAttrs v) curr);

      recurse = memo: queue:
        let
          curr = head queue;
          rest = tail queue;
        in
          if length queue == 0
          then memo
          else recurse (memo // compileone curr.key curr.val) (rest ++ getChildren curr.key curr.val);
   in recurse {} (prepQueue "" attrset);

  compile-commands = cmd: {flags ? ""}: attrs: assert flags != null;
    let
      go = k: v: assert hasAttr "set" v && hasAttr "flags" v;
        let _flags = lib.optionalString (v.flags != "") " -${v.flags}";
        in "${cmd}${_flags} ${k} ${v.set}";

    in mapAttrsToList go (expand-with-default-flags flags (compile-attrs attrs));

  compile-block = { options ? null, window-options ? null}:
    let
        mkOptions = compile-commands "set" {};
        mkWOptions = compile-commands "set" {flags="w";};
    in lib.optionals (options != null) (mkOptions options)
    ++ lib.optionals (window-options != null) (mkWOptions window-options)
    ;

  tests = rec {
    te1 = compile-attrs {
        window-status-current-format = {
          set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
          flags = "xg"; # wgg
        };
      };

    te2 = compile-attrs {
      window-status-current = {
        style = {bg="colour0";fg="colour11";attrs=["dim"];};
      };
    };
    te3 = compile-attrs {
      window-status-current = {
        format = {
          set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
          extra-flags = "xg"; # wgg
        };
      };
    };

    te4 = compile-attrs te4-1;

    te4-1 = expand-with-default-flags "q" te4-base;

    te4-base = {
      window-status-current = {
        set = true;
        flags = "xg"; # modify

        format = { set = "add flag q"; flags = "xg"; };
        mode = { set = null; };
        dangling = { donothing = ""; };
        style = {bg="colour0";fg="colour11";attrs=["dim"];};
        titles-string=''"#T"'';
      };
    };

    te5 = compile-commands "set" {flags="";} (expand-with-default-flags "g" te4-base);
    te6 = compile-commands "set" {flags="";} (expand-with-default-flags "g" te6-base);
    te6-1 = (expand-with-default-flags "g" te6-base);
    te6-base = {
      terminal-overrides = {
        set = ''"xterm*:XT:smcup@:rmcup@"'';
        flags = "g";
      };
      set-titles-string=''"#T"'';
      # Fixes for ssh-agent
      update-environment=''"SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION"'';
      mouse=true; # Enable mouse mode (tmux 2.1 and above)
      allow-rename=false;    # Stop renaming windows automatically
      renumber-windows=true; # But reorder windows automatically
    };

    lengths = [ (length test) 10 ];
    test = compile-block {
      options = expand-with-default-flags "g" {
        a = { set = true; flags = "w"; }; # "set -wg a on"
        b = quote "typechecks"; # "set -g b \"typechecks\""
        c = "unquoted"; # "set -g c unquoted"
        d = true; # "set -g d on"
        e = 20; # "set -g e 20"
        f = null; # "set -g f none"
      };
      window-options = expand-with-default-flags "g" {
        nest = {
          style = { bg="a";fg="b";attrs=["c"]; }; # "set -gw nest-style fg=b,bg=a,c"
          checks = 20; # "set -gw nest-checks 20"
          current = {
            style = {bg="0";fg="1"; flags = "q";}; # "set -qgw nest-current-style fg=1,bg=0"
            format = { set = quote "stuff"; flags = "xg"; }; # "set -xgw nest-current-format \"stuff\""
          };
        };
      };
    };

    window-options = expand-with-default-flags "g" {
        window-status = {
          styles = { bg="green";fg="black";attrs=["reverse"]; };
          format = ''"#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "'';
          current = {
            # "set -gw window-status-current-style fg=colour11,bg=colour0,dim"
            style = {bg="colour0";fg="colour11";attrs=["dim"];};
            # "set -xgq window-status-current-format \"stuff\""
            format = { set = quote "stuff"; flags = "xg"; };
          };
        };
      };
  };
}


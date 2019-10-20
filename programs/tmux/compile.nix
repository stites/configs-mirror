{ pkgs, lib, ... }:

with builtins; with lib.strings; with lib.attrsets; with lib.lists;
rec {
  compile = stuff:
    let go = s: if builtins.isString s then s else generic-args s;
    in concatStringsSep "\n" (map go (lib.lists.flatten stuff));

  unified-compile = stuff:
    let go = s: if builtins.isString s then s else unified-compile-one s;
    in concatStringsSep "\n" (map go (lib.lists.flatten stuff));

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
      eles   = filterAttrs (k: v: !(isStyles k v)) kwargs;
      styles = if hasAttr "styles" kwargs then getAttr "styles" kwargs else {};

      styleAsString = style: kv: "${style}-style ${smoosh-styles kv}";
      smoosh-styles = kv: concatStringsSep ","
        (  lib.optionals (hasAttr "fg" kv) ["fg=${kv.fg}"]
        ++ lib.optionals (hasAttr "bg" kv) ["bg=${kv.bg}"]
        ++ lib.optionals (hasAttr "attrs" kv && isList kv.attrs) kv.attrs);

    in mapAttrsToList (k: v: "${k} ${eleAsString v}") eles
      ++ mapAttrsToList styleAsString styles;

  isStyles = k: v: k == "styles" && isAttrs v;
  notStyles = k: v: !(isStyles k v);
  getStyles = kv: if hasAttr "styles" kv then getAttr "styles" kv else {};
  # generating arguments for generic-args
  quote  = s: assert builtins.isString s; "\"${s}\"";
  set    = kwargs: {cmd="set"; inherit kwargs;};
  setw   = kwargs: (set kwargs) // {flags="w";};
  set-g  = kwargs: (set kwargs) // {flags="g";};
  setw-g = kwargs: (set kwargs) // {flags="gw";};
  set-styles = style: attrs:
    let askwargs = k: v: {cmd="set"; flags="g"; kwargs={"${style}-style"="${k}=${v}";};};
    in mapAttrsToList askwargs attrs;
  setw-styles = style: attrs: map (set: set // {suffix = "w";}) (set-styles style attrs);

  options = kwargs: flags: set kwargs // flags; # set is an alias to set-option
  window-options = kwargs: flags:
    let xs = setw kwargs;
    in xs // (xs.flags + flags.flags); # set is an alias to set-option

  with-default-flags = dflags: attrset: assert isAttrs attrset;
    let
      mergeFlags = flags:
        concatStringsSep "" (unique (stringToCharacters flags ++ stringToCharacters dflags));

      go = attrset: memo: path: val:
        let
          curkey = last path;
          flagsibling = init path ++ ["flags"];
          flagchild = path ++ ["flags"];
          noFlag = nodetype: fpath: curkey == nodetype && !(hasAttrByPath fpath attrset);
          updateMemo = {
            inherit (memo) additional;
            updated = recursiveUpdate memo.updated (setAttrByPath path (mergeFlags val)); # update flags
          };
          flagAdditionalUpdate = fpath: {
            updated = memo.updated // setAttrByPath path val;
            additional = memo.additional // setAttrByPath fpath dflags; # signal flag to be added
          };
        in if "flags" == curkey
          then updateMemo
          else if noFlag "set" flagsibling # 'set' path with no flags
            then flagAdditionalUpdate flagsibling
            else if noFlag "style" flagchild
              then flagAdditionalUpdate flagchild
              else if isAttrs val
                then memo # do nothing until we make it to a leaf
                else updateMemo;
      result = recursive-update go {updated = {}; additional={};} attrset;
    in
      # result;
      recursiveUpdate result.updated result.additional;

  recursive-update = f: memo: attrset: assert isAttrs attrset;
    let
      prepQueue = ps: as: mapAttrsToList (k: v: { path = ps ++ [k]; val = v; }) as;
      getChildren = ps: curr: prepQueue ps (filterAttrs (k: v: isAttrs v) curr);
      recurse = memo: queue:
        let
          curr = head queue;
          rest = tail queue;
        in
          if length queue == 0
          then memo
          else recurse (f attrset memo curr.path curr.val) (rest ++ getChildren curr.path curr.val);
    in recurse memo (prepQueue [] attrset);

  _v2str = v:
    if isString v
      then v
      else if isBool v
        then if v then "on" else "off"
        else if v == null then "none"
          else toString v;



  compileone = k: v:
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
              then { inherit (v) set; }
              else {}
          ) // optionalAttrs (hasAttr "flags" v) { flags = v.flags; };
       };
    in lib.optionalAttrs isValid setting;

  compileit = attrset: assert isAttrs attrset; # && length (getKeys attrset) > 0;
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

  # unified-one-tl = cmd: k: v:
  #   let
  #     kv2str = k: v: k + (_v2str (if isAttrs v && hasAttr "set" v then v.set else v));
  #     getFlag = v: if isAttrs v && hasAttr "flags" v then v.flags else null;
  #   in lib.optional (if isAttrs v && hasAttr "set" v) [{ inherit cmd; flags = getFlag v; args = kv2str k v; }];

  # unified-compile-one = { cmd, flags ? "", args ? "" }:
  #   assert isString flags || flags == null;
  #   let _flags = lib.optionalString (isString flags && flags != "") "-${flags}";
  #   in "${cmd} ${_flags} ${args}";

  # parse-unified-kwargs = kwargs:
  #   let
  #     eleAsString = v:
  #       if isString v
  #         then v
  #         else if isBool v
  #           then (if v then "on" else "off")
  #           else if v == null then "none"
  #             else toString v;

  #     styleAsString = style: kv: "${style}-style ${smoosh-styles kv}";
  #     smoosh-styles = kv: concatStringsSep ","
  #       (  lib.optionals (hasAttr "fg" kv) ["fg=${kv.fg}"]
  #       ++ lib.optionals (hasAttr "bg" kv) ["bg=${kv.bg}"]
  #       ++ lib.optionals (hasAttr "attrs" kv && isList kv.attrs) kv.attrs);

  #   in mapAttrsToList (k: v: "${k} ${eleAsString v}") (filterAttrs notStyles kwargs)
  #     ++ mapAttrsToList styleAsString (getStyles kwargs);

  te1 = head (compileit te11);
  te11 = {
      window-status-current-format = {
        set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
        flags = "xg"; # wgg
      };
    };

  te2 = head (compileit te21);
  te21 = {
    window-status-current = {
      style = {bg="colour0";fg="colour11";attrs=["dim"];};
    };
  };
  te3 = head (compileit te31);
  te31 = {
    window-status-current = {
      format = {
        set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
        extra-flags = "xg"; # wgg
      };
    };
  };
  te4 = compileit te41;
  te41 = with-default-flags "q" {
    window-status-current = {
      set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
      flags = "xg"; # wgg

      format = {
        set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
        flags = "xg"; # wgg
      };
      style = {bg="colour0";fg="colour11";attrs=["dim"];};
    };
  };

  unified = { options ? null, window-options ? null}:
    let
        mkOptions = mapAttrsToList compileit;
        # mkWOptions = woptset: mkOptions (with-default-flags "w" woptset);

    in lib.optionals (options != null) options
    # ++ lib.optionals (window-options != null) (mkWOptions window-options)
    ;
  testy = with-default-flags "g" {
        # options = {
          terminal-overrides = {
            set = ''"xterm*:XT:smcup@:rmcup@"'';
            flags = "g";
          };
        #   set-titles-string=''"#T"'';
        };

  test = (unified {
        options = with-default-flags "g" {
        # options = {
          terminal-overrides = {
            set = ''"xterm*:XT:smcup@:rmcup@"'';
            flags = "g";
          };
        #   set-titles-string=''"#T"'';
        #   # Fixes for ssh-agent
        #   update-environment=''"SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION"'';
        #   mouse=true; # Enable mouse mode (tmux 2.1 and above)
        #   allow-rename=false;    # Stop renaming windows automatically
        #   renumber-windows=true; # But reorder windows automatically
        };
        window-options = with-default-flags "" {
          # window-status-format=''" #F#I:#W#F "'';
          # window-status-current-format=''" #F#I:#W#F "'';
          # window-status-format = {
          #   set = ''"#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "'';
          #   flags = "g"; #wg
          # };
          # window-status-current = {
          #   style = {bg="colour0";fg="colour11";attrs=["dim"];};
          # };
          window-status-current-format = {
            set = quote "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W ";
            extra-flags = "xg"; # wgg
          };
          # styles = {
          #   window-status = {bg="green";fg="black";attrs=["reverse"];};
            # window-status-current = ;
          # };
        };
      });
}


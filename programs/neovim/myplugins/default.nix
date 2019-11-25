# { python }:
{ lib, pkgs, ... }:
let
  validPluginFiles = (pkgs.callPackage ../plugin/functions.nix {}).validPluginFiles;
  compileAll = (pkgs.callPackage ../plugin/compile.nix {}).compileAll;

  plugins = [
    ./vim-polyglot.nix
    ./vim-multiple-cursors.nix
    ./themes/wombat256-vim.nix
    ./vim-sandwich.nix
    ./vim-commentary.nix
    ./vim-eunuch.nix
    ./vim-gutentags.nix
  ] ++ tmux-plugins
    ++ vim-plug-plugins
    ++ txt-plugins
    ++ layout-plugins
    # ++ coc-plugins
    ++ languageClient
    ;

  tmux-plugins = [
    ./vim-tmux-navigator.nix
    ./tslime.nix
  ];

  vim-plug-plugins = [
    ./vim-plug.nix # used instead of vim-wakatime.nix
    # ./vim-wakatime.nix
    # ./nvim-hs-vim.nix
  ];
  txt-plugins = [
    ./goyo-vim.nix
    ./vim-textobj-sentence.nix
    ./vim-speeddating.nix # increment dates with <c-x> and <c-a>
  ];

  layout-plugins = [
    ./vim-airline.nix
    ./vim-airline-theme.nix
    ./fzf-vim.nix
    ./vim-gitgutter.nix
    ./rainbow.nix
  ];

  languageClient = [
    ./LanguageClient-neovim/default.nix
  ];

  coc-plugins = let usetabnine = false; in [
    ./coc
    # ./coc/highlight.nix
    # ./coc/lists.nix
    ./coc/yank.nix
    ./coc/json.nix
    ./coc/snippets.nix
    ./coc/prettier.nix
  ] ++ (if usetabnine then [./coc/tabnine.nix] else [
    # ./neco.nix
    # ./html.nix
    # (./coc/python.nix python)
    ./coc/haskell.nix
    ./coc/python.nix
    ./coc/vimtex.nix
  ]);

in

assert validPluginFiles plugins;
with lib.attrsets; with lib.strings; with lib.lists;
let
  ps = compileAll plugins;
  inherit (pkgs) callPackage;
  flipCallPackage = p: callPackage p {};
in rec {
  plugins = filter (p: p != null) (map (p: p.pkg) ps);
  extraConfig = concatStringsSep "\n" (map (p: p.extraConfig) ps);

  # coc1 = (map flipCallPackage coc-plugins);

  # coc2 = map (p: optionalAttrs (p ? coc-settings) p.coc-settings)
  #         (map flipCallPackage coc-plugins);

  coc-settings = let
      allsettings =
        map (p: optionalAttrs (p ? coc-settings) p.coc-settings)
          (map flipCallPackage coc-plugins);
    in
      foldAttrs (new: memo: assert memo == null || memo == new; new) null allsettings;

  home.packages = lib.lists.flatten (map (p: lib.optionals (hasAttrByPath ["home" "packages"] p) p.home.packages) ps);
}


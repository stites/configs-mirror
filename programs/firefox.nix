{ pkgs, ... }:
let
  buildFirefoxXpiAddon = pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
in
{
  nixpkgs.overlays = [
    (import ../overlays/firefox-devedition.nix)
  ];

  programs.firefox = {
    enable = true;
    enableAdobeFlash = false;
    enableGoogleTalk = true;
    enableIcedTea = true;
    package = pkgs.firefox-devedition;
    #profiles."stites" = {
    #  id = 0;
    #  isDefault = true;
    #  extraConfig = ""; # Extra preferences to add to user.js.
    #  settings = {
    #    # Attribute set of Firefox preferences.
    #    "browser.newtabpage.enabled" = false;            # newtabs as blank pages
    #    "browser.urlbar.placeholderName" = "DuckDuckGo"; # use ddg
    #    "privacy.donottrackheader.enabled" = true;       # set "Do Not Track" to always
    #    "app.shield.optoutstudies.enabled" = false;      # opt out of studies
    #  };
    #  userChrome = pkgs.lib.strings.concatStringsSep "\n" [
    #    # Custom Firefox CSS.
    #    ''
    #    /* Hide tab bar in FF Quantum */
    #    @-moz-document url("chrome://browser/content/browser.xul") {
    #      #TabsToolbar {
    #        visibility: collapse !important;
    #        margin-bottom: 21px !important;
    #      }

    #      #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
    #        visibility: collapse !important;
    #      }
    #    }
    #    ''
    #  ];
    #};
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      (buildFirefoxXpiAddon { pname = "basic-json-formatter"; version = "1.1.0"; addonId = "{c7632bd5-48ce-467d-9433-58f33477553d}";
        url = "https://addons.mozilla.org/firefox/downloads/file/2846352/basic_json_formatter-1.1.0-an+fx.xpi=";
        sha256 = "0c86hmylfs87gdblsvkkh1cr3irmwri40k9qgwn6p14c1w2anfq0";
        # set `devtools.jsonview.enabled: false`
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "zotero-connector"; version = "5.0.60"; addonId = "zotero@chnm.gmu.edu";
        url = " https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.60.xpi";
        sha256 = "1c4n4rxcmf556nim2j5gwjf45ka63dr4bfy2rmbrnzfbvgrrp7hh";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "disable-webrtc"; version = "1.0.21"; addonId = "jid1-5Fs7iTLscUaZBgwr@jetpack";
        url = "https://addons.mozilla.org/firefox/downloads/file/3048824/disable_webrtc-1.0.21-an+fx.xpi";
        sha256 = "0qjzhjd4dlrvd2hzxibkjl8dsfjgi8g05z8qpjb60nhd8cpivqxp";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "duckduckgo-privacy-essentials"; version = "2019.9.12"; addonId = "jid1-ZAdIEUB7XOzOJw@jetpack";
        url = "https://addons.mozilla.org/firefox/downloads/file/3403443/duckduckgo_privacy_essentials-2019.9.12-an+fx.xpi";
        sha256 = "1v5ksl5yfklqwpslawkarn7w3ybf3nm5xayly7n9mbknx81df11k";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "github-code-folding"; version = "0.1.1"; addonId = "{b588f8ac-dbdf-4397-bcd7-3d29be2f17d7}";
        url = "https://addons.mozilla.org/firefox/downloads/file/569290/github_code_folding-0.1.1-an+fx.xpi";
        sha256 = "1a195hpzpc1kwf00y541hjgvqys9vnfps9iw48lzm8irs3xf9yb2";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "grammarly"; version = "8.852.2307"; addonId = "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack";
        url = "https://addons.mozilla.org/firefox/downloads/file/3000642/grammarly_for_firefox-8.852.2307-an+fx.xpi";
        sha256 = "13ygn7snv6rkncblcqqda3h984fhh8d3mwgwvanwn957dcyzg30q";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "lastpass"; version = "4.33.5.12"; addonId = "support@lastpass.com";
        url = "https://addons.mozilla.org/firefox/downloads/file/3411952/lastpass_password_manager-4.33.5.12-fx.xpi";
        sha256 = "12ahx3xm7lnrq7r41vybnz335nwhil3d5k1rwh4i36ks7k40fm3a";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "notes-by-firefox"; version = "4.3.5"; addonId = "notes@mozilla.com";
        url = "https://addons.mozilla.org/firefox/downloads/file/1751218/notes_by_firefox-4.3.5-fx.xpi";
        sha256 = "0b5wxl5jd1xpjdfdcr0jrrazh8jrbk9k8jpg436rv8605z9mpnjx";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "perma-cc"; version = "1.0.0"; addonId = "firefox@perma.cc";
        url = "https://addons.mozilla.org/firefox/downloads/file/503425/permacc-1.0.0-fx+an.xpi";
        sha256 = "0zvxmixkl1fk4jxvwmy13gmjgvj3q2990hyi5r3bih4ay3pg87mb";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname = "perma-cc"; version = "1.0.0"; addonId = "firefox@perma.cc";
        url = "https://addons.mozilla.org/firefox/downloads/file/503425/permacc-1.0.0-fx+an.xpi";
        sha256 = "0zvxmixkl1fk4jxvwmy13gmjgvj3q2990hyi5r3bih4ay3pg87mb";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname="arxiv-utils"; version="1.4"; addonId="ab779d78-7270-4ee8-9ee8-369d73508298";
        url = "https://addons.mozilla.org/firefox/downloads/file/3398798/arxiv_utils-1.4-an+fx.xpi";
        sha256 = "13nlqbh7bpl3j22rhfbjhdrj055b8slv6xzacy5wi6y165fndn8f";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname="Stackgo"; version="1.4"; addonId="bf16104d-6d4f-43d0-98ef-f7793e568b24";
        url = "https://addons.mozilla.org/firefox/downloads/file/669788/stackgo-1.4-an+fx.xpi";
        sha256 = "128yhgz8q0rrzdn5d4irci00wvg4g2g9diy95gwrblwh299qxy73";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname="py3redirect"; version="1.1.1"; addonId="c5a7894b-e3b0-457e-aa15-e1eb2b00d7a2";
        url = "https://addons.mozilla.org/firefox/downloads/file/564156/py3redirect-1.1.1-an+fx.xpi";
        sha256 = "1ghjrhh8mwv99yb23zgxsvn7xbdgi5rcaf8i5rg0sqj4f9bx4swm";
        meta = {};
      })
      # (buildFirefoxXpiAddon { pname="arxiv-url"; version="0.1"; addonId="e5849ea4-ac8c-4a75-896b-b2578970f1c0";
      #   url = "https://addons.mozilla.org/firefox/downloads/file/886406/arxiv_url-0.1-an+fx.xpi";
      #   sha256 = "1n89kxmljq8jfll5j9nmb1lssf9avsm832ivd10lfakv262yl3am";
      #   meta = {};
      # })
      (buildFirefoxXpiAddon { pname="Arxiv-Vanity"; version="0.1"; addonId="e92bf629-488c-4d5f-8771-04812b17c143";
        url = "https://addons.mozilla.org/firefox/downloads/file/3362708/arxiv_vanity-0.1-fx.xpi";
        sha256 = "0ln0bpq9khkhi7rai4cdrgha670w07brh1f78i9r8c6s0w6lla64";
        meta = {};
      })
      (buildFirefoxXpiAddon { pname="Enhancer-for-YouTube"; version="2.0.98.2"; addonId="enhancerforyoutube@maximerf.addons.mozilla.org";
        url = "https://addons.mozilla.org/firefox/downloads/file/3395753/enhancer_for_youtubetm-2.0.98.2-fx.xpi";
        sha256 = "1lqlzsq8hcg96930g5pniqmm820876ys3pfzhf2lbxln2hn6b1qw";
        meta = {};
      })
      auto-tab-discard
      https-everywhere
      privacy-badger
      decentraleyes
      facebook-container
      multi-account-containers
      refined-github
      ublock-origin
      # umatrix
      vim-vixen
    ];
  };
}

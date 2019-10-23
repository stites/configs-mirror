{ pkgs, ... }:
let
  inherit (pkgs.all-hies)
    # Install stable HIE for GHC versions 8.6.4 and 8.6.5 if available and fall back to unstable otherwise
    unstableFallback
    # Install stable HIE for GHC versions 8.6.4 and 8.6.5 only (ie: do not build from source if these do not exist.
    selection;

  hie-wrapper = selection { selector = p: { inherit (p) ghc864 ghc865; }; };
in
{
  name = "haskell-coc-language-server-configs";
  home.packages = [ hie-wrapper ];
  coc-settings = {
    languageserver = {
      haskell = {
        command = "${hie-wrapper}/bin/hie-wrapper";
        rootPatterns = [
          "stack.yaml"
          "cabal.config"
          "package.yaml"
        ];
        filetypes = [
          "hs"
          "lhs"
          "haskell"
        ];
        initializationOptions = {
          languageServerHaskell = {
            hlintOn = true;
          };
        };
      };
    };
  };
}

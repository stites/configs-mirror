{ lib, ... }:

# TODO: review https://wiki.haskell.org/GHC/GHCi#Pretty_Printing
let
  hoogle =
    # build up the hoogle function
    (let
      P = x: "Prelude." + x;
      return = P "return";
      asString = x: "(\"" + x + "\" :: " + P "String" + ")";
      cat = P "++";
      fun1 = arg: body: "\\ " + arg + " -> " + body;
      unwords = ws: lib.strings.concatStringsSep " " ws;
    # :def hoogle \s -> Prelude.return Prelude.$ (":! hoogle --count=15 \"" :: Prelude.String) Prelude.++ s Prelude.++ ("\"" :: Prelude.String)
    # :def hoogle \s -> return ((":! hoogle --count=15 \"" :: String) ++ s ++ ("\"" :: String))
    in
      ":def hoogle " +
      (fun1 "s" (unwords [
        return "(" (asString ":! hoogle --count=15 \\\"") cat "s" cat (asString "\\\"") ")"
      ]))
    );
in
{
  home.file.".ghci".text = lib.strings.concatStringsSep "\n" [
    # Turn off output for resource usage and types.  This is to reduce verbosity when reloading this file.
    ":unset +s +t"
    # Turn on multi-line input and remove the distracting verbosity.
    ":set +m -v0"
    # Set the preferred editor for use with the :e command.
    # I would recommend using an editor in a separate terminal, and using :r to reload, but :e can
    # still be useful for quick edits from within GHCi.
    ":set editor vim"
    # Turn off all compiler warnings and turn on OverloadedStrings for interactive input.
    ":seti -w -XOverloadedStrings"

    # turn on common ghci extensions
    ":set -XNumericUnderscores -XTupleSections -XPartialTypeSignatures"
    # ":set -XOverloadedStrings -XScopedTypeVariables -XFlexibleContexts -XDataKinds"

    # run all debug and assert cpp vars
    ":set -cpp -DASSERTS -DDEBUG"

    # don't warn about shadowing
    ":set -Wno-name-shadowing"

    # import stupidly important and basic things
    "import Data.Monoid ((<>))"

    # import incredibly useful packages
    ''
    :set -package text -package vector -package unordered-containers -package deepseq
    import Data.Text (Text)
    import qualified Data.Text   as T
    import Data.Vector (Vector)
    import qualified Data.Vector as V
    import Data.HashSet (HashSet)
    import qualified Data.HashSet as HS
    import Data.HashMap.Strict (HashMap)
    import qualified Data.HashMap.Strict as HM
    import Control.DeepSeq -- import everything
    ''

    # UDFs
    hoogle

    # numeric precision function
    "precision = \\n f-> (fromInteger $ round $ f * (10^n)) / (10.0^^n)"

    # import the prompt (and required packages)
    # ANSI escape sequences allow for displaying colours in compatible terminals.
    # See [http://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html this guide] for help interpreting them.
    ''
    :set -package directory -package filepath
    :{
      dotGHCI_myPrompt promptString ms _ = do
        cwd <- getcwd
        let main_module = head' [ m' | (m:m') <- ms, m == '*' ]
        return $ concat
          [ stx
          , startyellow
          , cwd
          , " ⊢ "
          -- , startblue
          , "ghci"
          , startyellow
          , main_module
          , startpurple
          , promptString
          , " "
          , clear, stx ]
        where
          stx = "\STX"
          startyellow = "\ESC[33m"
          startpurple = "\ESC[37m"
          startblue = "\ESC[34m"
          clear = "\ESC[0m"

          head' (x:_) = " \ESC[38;5;227m" ++ x
          head' _     = ""

          getcwd :: IO String
          getcwd = System.FilePath.Posix.takeBaseName <$> getpwd

          getpwd :: IO String
          getpwd = getpwd' <$> (System.Environment.getEnv "HOME") <*> System.Directory.getCurrentDirectory

          getpwd' home pwd = if zipWith const pwd home == home
                               then '~':drop (length home) pwd
                               else pwd
    :}
    :set prompt-function dotGHCI_myPrompt "\ESC[38;5;129m\xe61f"
    :set prompt-cont-function dotGHCI_myPrompt "::"
    ''
    # Use :rr to reload this file.
    ":def! rr \\_ -> return \":script ~/.ghci\""
    # Turn on output of types.  This line should be last.

    # Use :hmatrix to load static hmatrix tools
    ''
    :{
      :def! hmatrix \_ -> pure $ Data.List.intercalate "\n"
        [ ":set -XDataKinds -XTypeApplications"
        , ":set -package hmatrix"
        , "import Numeric.LinearAlgebra.Static"
        , "import GHC.TypeLits"
        , "import qualified Numeric.LinearAlgebra as LA"
        ]
    :}
    ''

    # Turn on output of types.  This line should be last.
    ":set +t"
  ];
}

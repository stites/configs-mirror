{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TupleSections #-}
import Data.Monoid ((<>))
import System.IO (hPutStrLn)
import Control.Monad.IO.Class (liftIO)
import Data.Map (Map)
import Graphics.X11.Xlib ()
import System.Exit (ExitCode(ExitSuccess), exitWith)
-- import PagerHints (pagerHints)

import XMonad
import XMonad.Actions.CycleWS (nextWS, prevWS, shiftToPrev, shiftToNext)
import XMonad.Actions.DynamicWorkspaces (addWorkspacePrompt, removeEmptyWorkspace)
import XMonad.Actions.SpawnOn (spawnOn, manageSpawn)
import XMonad.Actions.Search
import XMonad.Actions.Submap
import XMonad.Config.Desktop
import XMonad.Config.Xfce
import XMonad.Config.Gnome
import XMonad.Hooks.DynamicLog -- (xmobar, PP(..))
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.FadeWindows -- (fadeWindowsLogHook)
import XMonad.Hooks.ManageDocks (AvoidStruts, ToggleStruts(..), avoidStruts, docksEventHook, manageDocks, docks)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.SetWMName
import XMonad.Layout.BinarySpacePartition
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Layout.Maximize (Maximize, maximize, maximizeRestore)
import XMonad.ManageHook
import XMonad.Prompt (XPrompt, XPConfig(..))
import XMonad.Util.Cursor (setDefaultCursor)

import qualified Data.Map as M
import qualified XMonad.Hooks.DynamicLog as DLog
import qualified XMonad.Hooks.SetWMName as Window
import qualified XMonad.Layout.BinarySpacePartition as BSP
import qualified XMonad.Layout.IndependentScreens as LIS
import qualified XMonad.Layout.Spacing as Spacing
import qualified XMonad.Layout.WindowNavigation as Window (Navigate(..))
import qualified XMonad.Prompt as Prompt
import qualified XMonad.StackSet as W
import qualified XMonad.Util.Run as Run (safeSpawn, spawnPipe)
import qualified XMonad.Util.EZConfig as EZ

-- import System.Taffybar.Hooks.PagerHints (pagerHints)

launcherString = "rofi -combi-modi window,drun,ssh,run -show combi -modi combi -show drun -show-icons -drun-icon-theme -matching fuzzy -theme android_notification"

main :: IO ()
main
  = statusBar myBar myPP toggleStrutsKey myConfig
  >>= xmonad
 where
  myBar = "xmobar"

  -- Key binding to toggle the gap for the bar.
  toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

  myPP = xmobarPP
    { ppCurrent = DLog.xmobarColor "black" "gray"
    , ppHidden  = DLog.xmobarColor "orange" ""
    , ppHiddenNoWindows = id
    -- , ppOutput  = hPutStrLn xmproc
    , ppSep     = DLog.xmobarColor "orange" "" " | "
    , ppTitle   = DLog.xmobarColor "lightblue" "" . DLog.shorten 120
    , ppOrder   = \[a,_,b] -> [a, b]    -- Don't log layout name
    }

  myConfig
    = ewmh
    $ desktopConfig
      { modMask           = mod4Mask  -- Rebind Mod to super
      , terminal          = "kitty --single-instance" -- "urxvt" -- "/home/stites/.local/bin/termonad"
      , workspaces        = show <$> [1 .. 6]
      , borderWidth       = 4
      , focusFollowsMouse = False
      , manageHook        = manageDocks <+> launcherHook <+> manageSpawn <+> manageHook def
      , layoutHook        = myLayout
      , handleEventHook   = docksEventHook <+> handleEventHook def
      , startupHook = do
        spawnOn "1" "slack"
        spawnOn "1" "signal-desktop"
        -- spawnOn "1" "Gitter"
        spawnOn "2" "firefox"
        spawnOn "2" "kitty -1"
        spawnOn "3" "zotero"
        spawnOn "3" "protonmail-bridge"
        spawnOn "3" "thunderbird"
        spawnOn "4" "sudo plover"
      } `EZ.removeKeysP` removeKeys'
        `EZ.additionalKeysP` additionalKeys'

  launcherHook :: ManageHook
  launcherHook = resource =? launcherString --> doIgnore


type (:+) f g = Choose f g
infixr 5 :+

-- Frustrating, but
-- layout_hook
--   :: ModifiedLayout AvoidStruts
--        (ModifiedLayout Maximize
--          (ModifiedLayout SmartSpacing (BSP.BinarySpacePartition :+ Full)))
--      Window
myLayout = modify (emptyBSP ||| Full)
 where
  modify = avoidStruts . maximize . Spacing.smartSpacing 0
  tall = Tall 1 (3/100) (1/2)

removeKeys' :: [String]
removeKeys' =
  [ "M-S-<Return>" -- terminal
  , "M-S-c"        -- kill
  , "M-<Tab>"      -- focus down
  , "M-S-<Tab>"    -- focus up
  --, "M-<Space>"    -- rebind in additional keys
  , "M-h"          -- shrink
  , "M-l"          -- expand
  , "M-<Return>"   -- swap master
  , "M-m"          -- focus master
  ]


xpconfig :: XPConfig
xpconfig = Prompt.greenXPConfig
  { font = "-misc-fixed-*-*-*-*-20-*-*-*-*-*-*-*"
  , height = 26
  , historySize = 0
  , promptBorderWidth = 0
  }


additionalKeys' :: [(String, X ())]
additionalKeys'
  = windowsAndWorkspace
  <> applications
  <> system
  <> binaryPartitionLayout
  where
    windowsAndWorkspace :: [(String, X ())]
    windowsAndWorkspace =
      [ ("M-S-w",   kill)
      , ("M-l",   sendMessage $ Window.Go R)
      , ("M-h",   sendMessage $ Window.Go L)
      , ("M-S-c", removeEmptyWorkspace)
      -- , ("M-S-<Return>", myAddWorkspacePrompt xpconfig)
      , ("M-S-f", withFocused (sendMessage . maximizeRestore))
      -- , ("M-S-<Space>",  sendMessage ToggleLayout)
      -- , ("M-M1-h",       sendMessage Shrink)
      -- , ("M-M1-l",       sendMessage Expand)
      ]

    applications :: [(String, X ())]
    applications =
      [ ("M-o d",        spawn "thunar")
      , ("M-o h",        promptSearch xpconfig hackage)
      , ("M-<Return>",   spawn =<< asks (terminal . config))
      , ("<Print>",      spawn "flameshot gui")

      , ("C-S-<Space>",  spawn launcherString) -- old OSX style
      , ("M-p",          spawn launcherString) -- linux style
      ]

    system :: [(String, X ())]
    system = concat
      [ fmap (,spawn "amixer -q sset Master toggle") ["C-S-<F1>", "<XF86AudioMute>"]
      , fmap (,spawn "amixer -q sset Master 3%-")    ["C-S-<F2>", "<XF86AudioLowerVolume>"]
      , fmap (,spawn "amixer -q sset Master 3%+")    ["C-S-<F3>", "<XF86AudioRaiseVolume>"]
      , fmap (,spawn "xbacklight -dec 10")           ["C-S-<F5>", "<XF86MonBrightnessDown>"]
      , fmap (,spawn "xbacklight -inc 10")           ["C-S-<F6>", "<XF86MonBrightnessUp>"]
      , fmap (,spawn "xscreensaver-command -lock")   ["C-S-<F7>", "<XF86ModeLock>"]

      , [ ("M-b", sendMessage ToggleStruts)
        , ("M-S-<Delete>", spawn "pm-hibernate")
        -- , ("M-S-l",    spawn "xfce4-session-logout")
        ]
      ]

    binaryPartitionLayout =
      [ ("M-S-<Left>",    sendMessage $ BSP.ExpandTowards L)
      , ("M-S-<Right>",   sendMessage $ BSP.ExpandTowards R)
      , ("M-S-<Up>",      sendMessage $ BSP.ExpandTowards U)
      , ("M-S-<Down>",    sendMessage $ BSP.ExpandTowards D)

      , ("M-S-h",         sendMessage $ BSP.ExpandTowards L)
      , ("M-S-l",         sendMessage $ BSP.ExpandTowards R)
      , ("M-S-k",         sendMessage $ BSP.ExpandTowards U)
      , ("M-S-j",         sendMessage $ BSP.ExpandTowards D)

      , ("M-s",           sendMessage   BSP.Swap)
      , ("M-S-s",         sendMessage   Rotate)
      , ("M-S-p",         sendMessage   FocusParent)
      ]

-- Like promptSearchBrowser, but open it up so I have access to the flags to
-- pass to the browser. This lets me pass "--new-window" to chrome, so my
-- searches don't appear in new tabs on some random existing browser window.
promptSearchBrowser' :: XPConfig -> Browser -> SearchEngine -> X ()
promptSearchBrowser' config browser (SearchEngine name site) =
    Prompt.mkXPrompt (Search' name) config (Prompt.historyCompletionP ("Search [" `isPrefixOf`))
      (\query -> Run.safeSpawn browser ["--new-window", site query])

newtype Search' = Search' Name

instance XPrompt Search' where
  showXPrompt (Search' name)= "Search [" ++ name ++ "]: "
  nextCompletion _ = Prompt.getNextCompletion
  commandToComplete _ c = c



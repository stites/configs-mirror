{ lib, pkgs, stdenv, fetchgit, vimUtils, ... }:
let
  customPlugins = pkgs.callPackage ./plugins.nix {};
  pluginBuilder = pkgs.callPackage ./plugin/builder.nix {};

  myplugins = pkgs.callPackage ./myplugins {};
in
{
  xdg = {
    configFile = {
      "nvim/coc-settings.json".text = builtins.toJSON myplugins.coc-settings;
      "nvim/undodir/.empty".text = "";
      "nvim/init.vim".text = ''
        set shell=/bin/sh
      '';
      "nvim/UltiSnips/awk.snippets".source = ./UltiSnips/awk.snippets;
      "nvim/UltiSnips/c.snippets".source = ./UltiSnips/c.snippets;
      "nvim/UltiSnips/cmake.snippets".source = ./UltiSnips/cmake.snippets;
      "nvim/UltiSnips/cpp.snippets".source = ./UltiSnips/cpp.snippets;
      "nvim/UltiSnips/css.snippets".source = ./UltiSnips/css.snippets;
      "nvim/UltiSnips/cuda.snippets".source = ./UltiSnips/cuda.snippets;
      "nvim/UltiSnips/html.snippets".source = ./UltiSnips/html.snippets;
      "nvim/UltiSnips/julia.snippets".source = ./UltiSnips/julia.snippets;
      "nvim/UltiSnips/ledger.snippets".source = ./UltiSnips/ledger.snippets;
      "nvim/UltiSnips/make.snippets".source = ./UltiSnips/make.snippets;
      "nvim/UltiSnips/markdown.snippets".source = ./UltiSnips/markdown.snippets;
      "nvim/UltiSnips/purescript.snippets".source = ./UltiSnips/purescript.snippets;
      "nvim/UltiSnips/python.snippets".source = ./UltiSnips/python.snippets;
      "nvim/UltiSnips/r.snippets".source = ./UltiSnips/r.snippets;
      "nvim/UltiSnips/rust.snippets".source = ./UltiSnips/rust.snippets;
      "nvim/UltiSnips/sh.snippets".source = ./UltiSnips/sh.snippets;
      "nvim/UltiSnips/tex.snippets".source = ./UltiSnips/tex.snippets;
      "nvim/UltiSnips/vim.snippets".source = ./UltiSnips/vim.snippets;
      "nvim/UltiSnips/haskell.snippets" = {
        text = lib.strings.concatStringsSep "\n" [
          (builtins.readFile ./UltiSnips/haskell.snippets)
          ''
            snippet box "" !b
            -------------------------------------------------------------------------------
            -- |
            -- Module    :  `!v HaskellModuleName()`
            -- Copyright :  (c) Sam Stites 2017
            -- License   :  BSD-3-Clause
            -- Maintainer:  ${(import ../../secrets.nix).piis.address-rot13}
            -- Stability :  experimental
            -- Portability: non-portable
            -------------------------------------------------------------------------------

            endsnippet
          ''
        ];
      };
      "lsp/settings.json".text = ''
        {
          "languageServerHaskell": {
            "hlintOn": true,
            "maxNumberOfProblems": 10,
            "useCustomHieWrapper": true,
            "useCustomHieWrapperPath": "hie-wrapper"
          }
        }
      '';
    };
    dataFile = {
      "vim_gmake" = {
        executable = true;
        target = "../bin/vim_gmake";
        text = ''
          #!/usr/bin/env sh
          case "$(uname -o)" in
            "FreeBSD") gmake ;;
            *) make ;;
          esac
        '';
      };

      "vl" = {
        executable = true;
        target = "../bin/vl";
        source = ./exes/vl.sh;
      };

      "vim-plug" = {
        target = "nvim/site/autoload/plug.vim";
        source = (builtins.fetchTarball {
          url = "https://github.com/junegunn/vim-plug/archive/master.tar.gz";
        }) + "/plug.vim";
      };
    };
  };

  home.packages = [ ] ++ myplugins.home.packages;

  nixpkgs.overlays = [
    (self: super: let
      unstable = import <unstable> {};
    in {
      vimPlugins = unstable.vimPlugins;
      all-hies = import (fetchTarball "https://github.com/infinisil/all-hies/tarball/master") {};
    })
  ];

  programs.neovim = {
    enable = true;
    extraPython3Packages = (ps: with ps; [
      mccabe
      mypy
      nose
      pycodestyle
      pydocstyle

      jedi
      flake8
      pygments
      pytest-mypy
      pyls-isort
      pyls-mypy
      pyflakes
      yapf
    ]);
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
    package = pkgs.unstable.neovim.override {
      configure = {
        # CHECK OUT THIS FOR UPDATED CONTENT: https://nixos.wiki/wiki/Vim
        customRC = (pkgs.callPackage ./config.nix {}).extraConfig + myplugins.extraConfig;

        # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/vim.section.md
        packages.myVimPackage = { # with pkgs.vimPlugins; {
          # vim-plug management: loaded on launch
          # see examples below how to use custom packages
          start = myplugins.plugins;

          # If a Vim plugin has a dependency that is not explicitly listed in
          # opt that dependency will always be added to start to avoid confusion.
          opt = [ ];
        };
      };
    };

    ###########################################################################
    # vim-plug automatically executes `filetype plugin indent on` and `syntax enable`.
    # You can revert the settings after the call. (e.g. filetype indent off, syntax off, etc.)
    # plugins = myplugins.plugins;

    #   # ===============================================================================
    #   ''
    #   let g:haskell_tabular = 1

    #   vmap a= :Tabularize /=<CR>
    #   vmap a; :Tabularize /::<CR>
    #   vmap a- :Tabularize /-><CR>
    #   vmap am :Tabularize / as<CR>
    #   vmap a, :Tabularize /,<CR>
    #   ''

    #   # ==============================================================================
    #   # https://github.com/sol/hpack
    #   # run hpack automatically on modifications to package.yaml
    #   ''
    #   autocmd BufWritePost package.yaml silent !hpack --silent
    #   ''

    #   # Add these to your vimrc to automatically keep the tags file up to date.
    #   # Unfortunately silent means the errors look a little ugly, I suppose I could
    #   # capture those and print them out with echohl WarningMsg.
    #   ''
    #   au BufWritePost *.hs  silent !codex update --force %
    #   au BufWritePost *.hsc silent !codex update --force %
    #   ''

    #   # ==============================================================================
    #   # disable haskell indents
    #   ''
    #   let g:haskell_indent_disable=1
    #   " enable type information while typing
    #   let g:necoghc_enable_detailed_browse = 1
    #   " use stack in necoghc
    #   let g:necoghc_use_stack = 0

    #   " use haskell-ide-engine
    #   set hidden
    #   let g:LanguageClient_serverCommands = {
    #       \ 'haskell': ['hie', '--lsp'],
    #       \ }

    #   " let g:LanguageClient_rootMarkers = {
    #   "     \ 'haskell': ['cabal.project', 'stack.yaml'],
    #   "     \ }
    #   nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
    #   nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
    #   nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>
    #   ''

    #   # ==============================================================================
    #   # disable syntastic in python
    #   ''
    #   let g:syntastic_mode_map = { 'passive_filetypes': ['python'] }
    #   ''

    #   # ==============================================================================
    #   # Use deoplete.
    #   ''
    #   let g:deoplete#enable_at_startup = 1
    #   " disable autocomplete
    #   " let g:deoplete#disable_auto_complete = 1
    #   " inoremap <silent><expr><C-Space> deoplete#mappings#manual_complete()
    #   ''
    #   # ==============================================================================
    #   # UltiSnips config
    #   ''
    #   inoremap <silent><expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
    #   let g:UltiSnipsExpandTrigger="<tab>"
    #   let g:UltiSnipsJumpForwardTrigger="<tab>"
    #   let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
    #   ''

    #   # ==============================================================================
    #   # vim-session
    #   # https://peterodding.com/code/vim/session/
    #   # https://perma.cc/E487-SS2S
    #   ''
    #   let g:session_autoload = 'no'
    #   let g:session_autosave_periodic = 30   " minutes
    #   let g:session_directory = "/home/stites/.vim/session/"
    #   let g:session_lock_directory = "/home/stites/.vim/session-locks/"

    #   " Disable all session locking - I know what I'm doing :-).
    #   " let g:session_lock_enabled = 0

    # Files, backups and undo {{{

    ## # # ALTERNATIVE: Utility function to delete trailing white space
    ## # ''
    ## # fun! DeleteTrailingWS()
    ## #   exe "normal mz"
    ## #   %s/\s\+$//ge
    ## #   exe "normal `z"
    ## # endfun
    ## # " autocmd BufWritePre * :call DeleteTrailingWS()
    ## # ''
    ## # }}}

    # not installed
    #   ''
    #   function! CmdLine(str)
    #     exe "menu Foo.Bar :" . a:str
    #     emenu Foo.Bar
    #     unmenu Foo
    #   endfunction
    #   ''
    #   # Moving around, tabs, windows and buffers {{{

    #   # Disable highlight when <leader><cr> is pressed
    #   # but preserve cursor coloring
    #   ''
    #   nmap <silent> <leader><cr> :noh\|hi Cursor guibg=red<cr>

    #   " Return to last edit position when opening files (You want this!)
    #   augroup last_edit
    #     autocmd!
    #     autocmd BufReadPost *
    #          \ if line("'\"") > 0 && line("'\"") <= line("$") |
    #          \   exe "normal! g`\"" |
    #          \ endif
    #   augroup END
    #   ''
    #   # Open window splits in various places
    #   "nmap <leader>sh :leftabove  vnew<CR>"
    #   "nmap <leader>sl :rightbelow vnew<CR>"
    #   "nmap <leader>sk :leftabove  new<CR>"
    #   "nmap <leader>sj :rightbelow new<CR>"

    #   # previous buffer, next buffer
    #   "nnoremap <leader>bp :bp<cr>"
    #   "nnoremap <leader>bn :bn<cr>"

    #   # close every window in current tabview but the current
    #   "nnoremap <leader>bo <c-w>o"

    #   # delete buffer without closing pane
    #   "noremap <leader>bd :Bd<cr>"

    #   # fuzzy find buffers
    #   "noremap <leader>b<space> :CtrlPBuffer<cr>"

    #   # Alignment {{{

    #   # Stop Align plugin from forcing its mappings on us
    #   "let g:loaded_AlignMapsPlugin=1"
    #   # Align on equal signs
    #   "map <Leader>a= :Align =<CR>"
    #   # Align on commas
    #   "map <Leader>a, :Align ,<CR>"
    #   # Align on pipes
    #   "map <Leader>a<bar> :Align <bar><CR>"
    #   # Prompt for align character
    #   "map <leader>ap :Align"

    #   # }}}
    #   ''
    #   " Completion {{{
    #   set completeopt+=longest

    #   " Use buffer words as default tab completion
    #   let g:SuperTabDefaultCompletionType = '<c-x><c-p>'

    #   " }}}
    #   ''

    #   # Tabnine experiment
    #   # "set rtp+=~/tabnine-vim"
    # ]);
  };
}

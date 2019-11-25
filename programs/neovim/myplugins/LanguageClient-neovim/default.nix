{ pkgs, ... }:
let
  keybindings = (pkgs.callPackage ../../keybindings {});
  leader = keybindings.leader;
  lsp-var = { namespace ? "" }: cmd: "LanguageClient${namespace}_${cmd}";
  ctx-menu = lsp-var {} "contextMenu()";
  txtdoc = cmd: lsp-var {namespace="#textDocument";} cmd;
  serverCommands = lsp-var {} "serverCommands";

  inherit (pkgs.all-hies)
    # Install stable HIE for GHC versions 8.6.4 and 8.6.5 if available and fall back to unstable otherwise
    unstableFallback
    # Install stable HIE for GHC versions 8.6.4 and 8.6.5 only (ie: do not build from source if these do not exist.
    selection;

  hie-wrapper = selection { selector = p: { inherit (p) ghc865; }; };
in
with keybindings.lib;

{
  pkg = pkgs.vimPlugins.LanguageClient-neovim;
  # priority = 100;

  home.packages = [ hie-wrapper ];

  dependencies = [
    ../fzf-vim.nix
    ../deoplete-nvim.nix
  ];

  extraConfig = [
    # Required for operations modifying multiple buffers like rename.
    "set hidden"

    "let g:${serverCommands} = {"
    # "\\ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],"
    # "\\ 'javascript': ['/usr/local/bin/javascript-typescript-stdio'],"
    # "\\ 'javascript.jsx': ['tcp://127.0.0.1:2089'],"
    "\\ 'python': ['pyls'],"
    "\\'haskell': ['${hie-wrapper}/bin/hie-wrapper'],"
    # "\\ 'ruby': ['~/.rbenv/shims/solargraph', 'stdio'],"
    "\\ }"

    (function "LC_maps" {} (vimif "has_key(g:${serverCommands}, &filetype)" [
        "nnoremap <F5> :call LanguageClient_contextMenu()<CR>"

        # Or map each action separately
        (nnoremap { key="${leader}lk"; silent=true; cmd=":call ${txtdoc "hover()<CR>"}";})
        (nnoremap { key="${leader}lg"; silent=true; cmd=":call ${txtdoc "definition()<CR>"}";})
        (nnoremap { key="${leader}lr"; silent=true; cmd=":call ${txtdoc "rename()<CR>"}";})
        (nnoremap { key="${leader}<F2>"; silent=true; cmd=":call ${txtdoc "rename()<CR>"}";})
        (nnoremap { key="${leader}lf"; silent=true; cmd=":call ${txtdoc "formatting()<CR>"}";})
        (nnoremap { key="${leader}lb"; silent=true; cmd=":call ${txtdoc "references()<CR>"}";})
        (nnoremap { key="${leader}la"; silent=true; cmd=":call ${txtdoc "codeAction()<CR>"}";})
        (nnoremap { key="${leader}ls"; silent=true; cmd=":call ${txtdoc "documentSymbol()<CR>"}";})
      ]))

    (autocmd {types="FileType"; middlething="*";} "LC_maps()")

    # If you'd like diagnostics to be highlighted, add a highlight group for ALEError/ALEWarning/ALEInfo, or customize
    # g:LanguageClient_diagnosticsDisplay:
    ''
    hi link ALEError Error
    hi Warning term=underline cterm=underline ctermfg=Yellow gui=undercurl guisp=Gold
    hi link ALEWarning Warning
    hi link ALEInfo SpellCap
    ''

    # =========================================================================
    # from Coc:
    # =========================================================================
    # Some servers have issues with backup files, see #649
    "set nobackup nowritebackup"

    # # Better display for messages
    # "set cmdheight=2"

    # # You will have bad experience for diagnostic messages when it's default 4000.
    # "set updatetime=300"

    # # # don't give |ins-completion-menu| messages.
    # # "set shortmess+=c"

    # # always show signcolumns
    # "set signcolumn=yes"
  ];
}

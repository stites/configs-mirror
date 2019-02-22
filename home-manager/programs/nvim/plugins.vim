" using vim-plug
call plug#begin('~/.local/share/nvim/site/')

" handle loading in configs:
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash ./install.sh',
    \ }
" Use with LSP to search for, substitute, and abbreviate multiple variants of a word
Plug "tpope/vim-abolish"

" C/C++ development
Plug 'JBakamovic/cxxd-vim', { 'for': ['c', 'cpp'] }

" Dhall
Plug 'vmchale/dhall-vim',     { 'for': 'dhall' }

" Haskell
Plug 'neovimhaskell/haskell-vim',     { 'for': 'haskell' }
Plug 'Twinside/vim-hoogle',           { 'for': 'haskell' }
Plug 'mpickering/hlint-refactor-vim', { 'for': 'haskell' }
Plug 'eagletmt/neco-ghc',             { 'for': 'haskell' }
Plug 'meck/vim-brittany',             { 'for': 'haskell' }

" HTML, XML
Plug 'docunext/closetag.vim', { 'for': 'html' }

" elm - elm-vim MUST be before vim-polyglot
Plug 'ElmCast/elm-vim', { 'for': 'elm' }

" ruby
Plug 'tpope/vim-endwise', { 'for': 'ruby' }

" LaTeX plugins
Plug 'lervag/vimtex', { 'for': 'latex' }

" C++ plugins
Plug 'Rip-Rip/clang_complete', { 'for': 'c' }

" HLedger
Plug 'anekos/hledger-vim', { 'for': 'journal' }


" SYSTEM PLUGINS
"

" Haskell, always-on
Plug 'ndmitchell/ghcid', { 'rtp': 'plugins/nvim' }
Plug 'hspec/hspec.vim'

" Support bundles
Plug 'jgdavey/tslime.vim'
Plug 'Shougo/vimproc.vim', { 'do': 'vim_gmake' }
Plug 'sheerun/vim-polyglot'

" Plug 'ervandew/supertab'
Plug 'benekastah/neomake'
Plug 'moll/vim-bbye'
Plug 'nathanaelkane/vim-indent-guides'
" Plug 'vim-scripts/gitignore'
Plug 'SirVer/ultisnips'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'nacitar/terminalkeys.vim'
Plug 'xolox/vim-session' | Plug 'xolox/vim-misc'
Plug 'qpkorr/vim-bufkill'
Plug 'tpope/vim-eunuch'
Plug 'mbbill/undotree'

" Git
" Plug 'int3/vim-extradite'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb' | Plug 'tpope/vim-fugitive'

" Bars, panels, and files
" Plug 'scrooloose/nerdtree'
Plug 'bling/vim-airline'
" Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf.vim' | Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-unimpaired'
" Plug 'majutsushi/tagbar'                 " http://vimawesome.com/plugin/tagbar
" Plug 'Xuyuanp/nerdtree-git-plugin'

" Text manipulation
Plug 'vim-scripts/Align'
Plug 'simnalamburt/vim-mundo'
Plug 'tpope/vim-commentary'
Plug 'godlygeek/tabular'
Plug 'michaeljsmith/vim-indent-object'
Plug 'easymotion/vim-easymotion'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-surround'                " http://vimawesome.com/plugin/surround-vim
Plug 'tpope/vim-repeat'                  " to be used with vim-surround
Plug 'tpope/vim-speeddating'
Plug 'vim-syntastic/syntastic'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/rainbow_parentheses.vim'
Plug 'pelodelfuego/vim-swoop'

" Allow pane movement to jump out of vim into tmux
Plug 'christoomey/vim-tmux-navigator'

" Colorscheme
Plug 'vim-scripts/wombat256.vim'
Plug 'endel/vim-github-colorscheme'
Plug 'mhartington/oceanic-next'
Plug 'freeo/vim-kalisi'
Plug 'JBakamovic/yaflandia'

" Productivity
" Plug 'wakatime/vim-wakatime'
Plug 'jceb/vim-orgmode' | Plug 'mattn/calendar-vim' | Plug 'inkarkat/vim-SyntaxRange' | Plug 'vim-scripts/utl.vim'

" Vim improvements:
Plug 'kana/vim-textobj-user' | Plug 'reedes/vim-textobj-sentence'

" Python
" Plug 'nvie/vim-flake8', { 'for': 'python' }
" Plug 'vim-scripts/indentpython.vim', { 'for': 'python' }
" Plug 'szymonmaszke/vimpyter'

" Automatically executes `filetype plugin indent on` and `syntax enable`.
" You can revert the settings after the call. (e.g. filetype indent off, syntax off, etc.)
call plug#end()
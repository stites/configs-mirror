{ pkgs, ... }:
{
  pkg = pkgs.vimPlugins.coc-snippets;
  extraConfig = [
    # Use <C-l> for trigger snippet expand.
    "imap <C-l> <Plug>(coc-snippets-expand)"

    # Use <C-j> for select text for visual placeholder of snippet.
    "vmap <C-j> <Plug>(coc-snippets-select)"

    # Use <C-j> for jump to next placeholder, it's default of coc.nvim
    "let g:coc_snippet_next = '<c-j>'"

    # Use <C-k> for jump to previous placeholder, it's default of coc.nvim
    "let g:coc_snippet_prev = '<c-k>'"

    # Use <C-j> for both expand and jump (make expand higher priority.)
    "imap <C-j> <Plug>(coc-snippets-expand-jump)"

    # Make <tab> used for trigger completion, completion confirm, snippet expand and jump like VSCode.
    ''
    function! s:check_back_space() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~# '\s'
    endfunction
    ''

    # ''
    # inoremap <silent><expr> <TAB>
    #       \ pumvisible() ?  :
    #       \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''''''])\<CR>" :
    #       \ <SID>check_back_space() ? "\<TAB>" :
    #       \ coc#refresh()
    # ''
    (let
      # coc#_select_confirm() helps select first complete item when there's no complete item selected. I think it's too intuitive
      choosenext = if false then "coc#_select_confirm()" else ''"\<C-n>"'';
    in ''
    inoremap <silent><expr> <TAB>
          \ pumvisible() ? ${choosenext} :
          \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump','''])\<CR>" :
          \ <SID>check_back_space() ? "\<TAB>" :
          \ coc#refresh()
    '')

# inoremap <silent><expr> <TAB>
#       \ pumvisible() ? coc#_select_confirm() :
#       \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
#       \ <SID>check_back_space() ? "\<TAB>" :
#       \ coc#refresh()
    ''
    let g:coc_snippet_next = '<tab>'
    ''
  ];
}

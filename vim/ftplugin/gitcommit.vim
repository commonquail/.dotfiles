autocmd! vimrcEx BufReadPost *
setlocal spell spelllang=en_gb

if executable("commitmsgfmt")
  setlocal formatprg=commitmsgfmt
  setlocal textwidth=0
  setlocal wrap

  nnoremap <buffer> <silent> <LocalLeader>gq :let b:cursorpos=winsaveview()<CR>gggqG:call winrestview(b:cursorpos)<CR>
  nmap <buffer> gqip <LocalLeader>gq
else
  setlocal formatoptions+=n
  setlocal formatoptions+=q
  " Amend default number-list formatting to include dash- and bullet lists.
  setlocal formatlistpat=^\\s*[-*0-9]\\+[\]:.)}\\t\ ]\\s*
endif

command! -buffer -nargs=1 Reference :call s:reference(<q-args>)

function! s:reference(rev)
  if match(a:rev, "^/") != -1
    let query = "HEAD^{" . a:rev . "}"
  else
    let query = a:rev
  endif
  let query = shellescape(query, 1)
  let cmd = "git show -s --pretty=reference " . query . " --"
  silent exe "read !" . cmd
endfunction

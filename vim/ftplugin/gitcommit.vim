autocmd! vimrcEx BufReadPost *
setlocal spell spelllang=en_gb
setlocal formatoptions+=n
setlocal formatoptions+=q
" Amend default number-list formatting to include dash- and bullet lists.
setlocal formatlistpat=^\\s*[-*0-9]\\+[\]:.)}\\t\ ]\\s*

command! -buffer -nargs=1 Reference :call s:reference(<q-args>)

function! s:reference(rev)
  if match(a:rev, "^/") != -1
    let query = "HEAD^{" . a:rev . "}"
  else
    let query = a:rev
  endif
  let query = shellescape(query, 1)
  let pretty = shellescape('%h ("%s", %ad)', 1)
  let git_log = "git log -1 --date=short --format=" . pretty . " " . query . " --"
  silent exe "read !" . git_log
endfunction

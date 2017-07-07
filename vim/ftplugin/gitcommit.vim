autocmd! vimrcEx BufReadPost *
setlocal spell spelllang=en_gb
setlocal formatoptions+=n
setlocal comments=b:#,n:>,fb:-,fb:*

command! -buffer -nargs=1 Reference :call s:reference(<q-args>)

function! s:reference(rev)
  if match(a:rev, "^/") != -1
    let query = "HEAD^{" . a:rev . "}"
  else
    let query = a:rev
  endif
  let query = shellescape(query, 1)
  let pretty = shellescape('%h ("%s")', 1)
  let git_log = "git log -1 --format=" . pretty . " " . query . " --"
  silent exe "read !" . git_log
endfunction

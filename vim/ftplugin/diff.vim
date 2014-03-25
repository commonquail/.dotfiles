" Count the total number of hunk lines after applying patch.
function! s:hunklines()
  let l:numlines = 0
  let l:started = 0

  for line in getline(1, "$")
    " Git diffs start and end with #. Use this to shirt-circuit.
    if l:line =~ '^#'
      if l:started == 1
        break
      endif
      let l:started = 1
    elseif l:line =~ "^[ +]"
      let l:numlines += 1
    elseif l:line =~ '^-'
      let l:numlines -= 1
    endif
  endfor

  echo "New line count: " . l:numlines
endfunction

command! -buffer -bar HunkLines :call s:hunklines()

augroup PrintLineCount
  autocmd! BufWritePost <buffer> :call s:hunklines()
augroup END

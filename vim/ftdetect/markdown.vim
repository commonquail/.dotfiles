autocmd BufNewFile,BufRead *.tex
      \ if &ft =~# '^\%(conf\|modula2\)$' |
      \   set ft=latex |
      \ else |
      \   setf latex |
      \ endif

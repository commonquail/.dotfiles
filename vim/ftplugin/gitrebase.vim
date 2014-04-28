augroup DisableLastPositionJump
  autocmd! BufWinEnter <buffer> execute "normal! gg0" |
        \ autocmd! DisableLastPositionJump BufWinEnter <buffer>
augroup END

nnoremap <buffer> <silent> gp :Pick<CR>
nnoremap <buffer> <silent> gs :Squash<CR>
nnoremap <buffer> <silent> ge :Edit<CR>
nnoremap <buffer> <silent> gr :Reword<CR>
nnoremap <buffer> <silent> gf :Fixup<CR>
nnoremap <buffer> <silent> S :Cycle<CR>

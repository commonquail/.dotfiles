if exists("current_compiler")
  finish
endif
let current_compiler = "php"

if exists(":CompilerSet") != 2 " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=php\ -l\ %
CompilerSet errorformat=%m\ in\ %f\ on\ line\ %l

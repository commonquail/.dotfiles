" Vim compiler file
" Compiler:	Miscrosoft Visual C
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2005 Nov 30

if exists("current_compiler")
  finish
endif
let current_compiler = "msvc"

" The errorformat for MSVC is the default.
"CompilerSet errorformat&
CompilerSet makeprg=\"\"D:\\\\Programmer\\Microsoft\ Visual\ Studio\ 10.0\\VC\\bin\\vcvars32.bat\"\&\&cl\ /W3\ %\ 2>&1\"

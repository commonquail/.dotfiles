" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal cindent
setlocal indentkeys& indentkeys+=0=in indentkeys+=0=out indentkeys+=0=body
setlocal indentexpr=GetDIndent()

if exists("*GetDIndent")
  finish
endif

function! SkipBlanksAndComments(startline)
  let lnum = a:startline
  while lnum > 1
    let lnum = prevnonblank(lnum)
    if getline(lnum) =~ '[*+]/\s*$'
      while getline(lnum) !~ '/[*+]' && lnum > 1
	let lnum = lnum - 1
      endwhile
      if getline(lnum) =~ '^\s*/[*+]'
	let lnum = lnum - 1
      else
	break
      endif
    elseif getline(lnum) =~ '\s*//'
      let lnum = lnum - 1
    else
      break
    endif
  endwhile
  return lnum
endfunction

function GetDIndent()
  let lnum = v:lnum
  let line = getline(lnum)

  " Align body{}, in{}, out{} with function signature.
  if line =~ '^\s*\(body\|in\|out\)\>'
    return cindent(SkipBlanksAndComments(lnum - 1))
  endif

  return cindent(lnum)
endfunction

" vim: shiftwidth=2 expandtab

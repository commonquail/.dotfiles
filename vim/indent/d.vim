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
  let cind = cindent(lnum)

  " Align contract blocks with function signature.
  if line =~ '^\s*\(body\|in\|out\)\>'
    " Skip in/out parameters.
    if getline(lnum - 1) =~ '[(,]\s*$'
      return cind
    endif
    " Find the end of the last block or the function signature.
    if line !~ '^\s*}' && getline(lnum - 1) !~ '('
      while getline(lnum - 1) !~ '[(}]'
	let lnum = lnum - 1
      endwhile
    endif
    let lnum = SkipBlanksAndComments(lnum)
    return cindent(lnum - 1)
  endif

  return cind
endfunction

" vim: shiftwidth=2 expandtab

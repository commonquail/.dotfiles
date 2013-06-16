" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
ftplugin/tex_LatexBox.vim	[[[1
32
" LaTeX Box plugin for Vim
" Maintainer: David Munger
" Email: mungerd@gmail.com
" Version: 0.9.6

if has('*fnameescape')
	function! s:FNameEscape(s)
		return fnameescape(a:s)
	endfunction
else
	function! s:FNameEscape(s)
		return a:s
	endfunction
endif

if !exists('s:loaded')

	let prefix = expand('<sfile>:p:h') . '/latex-box/'

	execute 'source ' . s:FNameEscape(prefix . 'common.vim')
	execute 'source ' . s:FNameEscape(prefix . 'complete.vim')
	execute 'source ' . s:FNameEscape(prefix . 'motion.vim')
	execute 'source ' . s:FNameEscape(prefix . 'latexmk.vim')

	let s:loaded = 1

endif

execute 'source ' . s:FNameEscape(prefix . 'mappings.vim')
execute 'source ' . s:FNameEscape(prefix . 'indent.vim')

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/common.vim	[[[1
311
" LaTeX Box common functions

" Settings {{{

" Compilation {{{

" g:vim_program {{{
if !exists('g:vim_program')

	if match(&shell, '/bash$') >= 0
		let ppid = '$PPID'
	else
		let ppid = '$$'
	endif

	" attempt autodetection of vim executable
	let g:vim_program = ''
	let tmpfile = tempname()
	silent execute '!ps -o command= -p ' . ppid . ' > ' . tmpfile
	for line in readfile(tmpfile)
		let line = matchstr(line, '^\S\+\>')
		if !empty(line) && executable(line)
			let g:vim_program = line . ' -g'
			break
		endif
	endfor
	call delete(tmpfile)

	if empty(g:vim_program)
		if has('gui_macvim')
			let g:vim_program = '/Applications/MacVim.app/Contents/MacOS/Vim -g'
		else
			let g:vim_program = v:progname
		endif
	endif
endif
" }}}

if !exists('g:LatexBox_latexmk_options')
	let g:LatexBox_latexmk_options = ''
endif
if !exists('g:LatexBox_output_type')
	let g:LatexBox_output_type = 'pdf'
endif
if !exists('g:LatexBox_viewer')
	let g:LatexBox_viewer = 'xdg-open'
endif
if !exists('g:LatexBox_autojump')
	let g:LatexBox_autojump = 0
endif
" }}}

" Completion {{{
if !exists('g:LatexBox_completion_close_braces')
	let g:LatexBox_completion_close_braces = 1
endif
if !exists('g:LatexBox_bibtex_wild_spaces')
	let g:LatexBox_bibtex_wild_spaces = 1
endif

if !exists('g:LatexBox_cite_pattern')
	let g:LatexBox_cite_pattern = '\C\\cite\(p\|t\)\=\*\=\(\[[^\]]*\]\)*\_\s*{'
endif
if !exists('g:LatexBox_ref_pattern')
	let g:LatexBox_ref_pattern = '\C\\v\?\(eq\|page\)\?ref\*\?\_\s*{'
endif

if !exists('g:LatexBox_completion_environments')
	let g:LatexBox_completion_environments = [
		\ {'word': 'itemize',		'menu': 'bullet list' },
		\ {'word': 'enumerate',		'menu': 'numbered list' },
		\ {'word': 'description',	'menu': 'description' },
		\ {'word': 'center',		'menu': 'centered text' },
		\ {'word': 'figure',		'menu': 'floating figure' },
		\ {'word': 'table',			'menu': 'floating table' },
		\ {'word': 'equation',		'menu': 'equation (numbered)' },
		\ {'word': 'align',			'menu': 'aligned equations (numbered)' },
		\ {'word': 'align*',		'menu': 'aligned equations' },
		\ {'word': 'document' },
		\ {'word': 'abstract' },
		\ ]
endif

if !exists('g:LatexBox_completion_commands')
	let g:LatexBox_completion_commands = [
		\ {'word': '\begin{' },
		\ {'word': '\end{' },
		\ {'word': '\item' },
		\ {'word': '\label{' },
		\ {'word': '\ref{' },
		\ {'word': '\eqref{eq:' },
		\ {'word': '\cite{' },
		\ {'word': '\chapter{' },
		\ {'word': '\section{' },
		\ {'word': '\subsection{' },
		\ {'word': '\subsubsection{' },
		\ {'word': '\paragraph{' },
		\ {'word': '\nonumber' },
		\ {'word': '\bibliography' },
		\ {'word': '\bibliographystyle' },
		\ ]
endif
" }}}

" Vim Windows {{{
if !exists('g:LatexBox_split_width')
	let g:LatexBox_split_width = 30
endif
" }}}
" }}}

" Filename utilities {{{
"
function! LatexBox_GetMainTexFile()

	" 1. check for the b:main_tex_file variable
	if exists('b:main_tex_file') && glob(b:main_tex_file, 1) != ''
		return b:main_tex_file
	endif

	" 2. scan current file for "\begin{document}"
	if &filetype == 'tex' && search('\C\\begin\_\s*{document}', 'nw') != 0
		return expand('%:p')
	endif

	" 3. prompt for file with completion
	let b:main_tex_file = s:PromptForMainFile()
	return b:main_tex_file
endfunction

function! s:PromptForMainFile()
	let saved_dir = getcwd()
	execute 'cd ' . fnameescape(expand('%:p:h'))
	let l:file = ''
	while glob(l:file, 1) == ''
		let l:file = input('main LaTeX file: ', '', 'file')
		if l:file !~ '\.tex$'
			let l:file .= '.tex'
		endif
	endwhile
	execute 'cd ' . fnameescape(saved_dir)
	return l:file
endfunction

" Return the directory of the main tex file
function! LatexBox_GetTexRoot()
	return fnamemodify(LatexBox_GetMainTexFile(), ':h')
endfunction

function! LatexBox_GetTexBasename(with_dir)
	if a:with_dir
		return fnamemodify(LatexBox_GetMainTexFile(), ':r')
	else
		return fnamemodify(LatexBox_GetMainTexFile(), ':t:r')
	endif
endfunction

function! LatexBox_GetAuxFile()
	return LatexBox_GetTexBasename(1) . '.aux'
endfunction

function! LatexBox_GetLogFile()
	return LatexBox_GetTexBasename(1) . '.log'
endfunction

function! LatexBox_GetOutputFile()
	return LatexBox_GetTexBasename(1) . '.' . g:LatexBox_output_type
endfunction
" }}}

" View Output {{{
function! LatexBox_View()
	let outfile = LatexBox_GetOutputFile()
	if !filereadable(outfile)
		echomsg fnamemodify(outfile, ':.') . ' is not readable'
		return
	endif
	let cmd = '!' . g:LatexBox_viewer . ' ' . shellescape(outfile) . ' >&/dev/null &'
	silent execute cmd
	if !has("gui_running")
		redraw!
	endif
endfunction

command! LatexView			call LatexBox_View()
" }}}

" In Comment {{{
" LatexBox_InComment([line], [col])
" return true if inside comment
function! LatexBox_InComment(...)
	let line	= a:0 >= 1 ? a:1 : line('.')
	let col		= a:0 >= 2 ? a:2 : col('.')
	return synIDattr(synID(line("."), col("."), 0), "name") =~# '^texComment'
endfunction
" }}}

" Get Current Environment {{{
" LatexBox_GetCurrentEnvironment([with_pos])
" Returns:
" - environment													if with_pos is not given
" - [envirnoment, lnum_begin, cnum_begin, lnum_end, cnum_end]	if with_pos is nonzero
function! LatexBox_GetCurrentEnvironment(...)

	if a:0 > 0
		let with_pos = a:1
	else
		let with_pos = 0
	endif

	let begin_pat = '\C\\begin\_\s*{[^}]*}\|\\\@<!\\\[\|\\\@<!\\('
	let end_pat = '\C\\end\_\s*{[^}]*}\|\\\@<!\\\]\|\\\@<!\\)'
	let saved_pos = getpos('.')

	" move to the left until on a backslash
	let [bufnum, lnum, cnum, off] = getpos('.')
	let line = getline(lnum)
	while cnum > 1 && line[cnum - 1] != '\'
		let cnum -= 1
	endwhile
	call cursor(lnum, cnum)

	" match begin/end pairs but skip comments
	let flags = 'bnW'
	if strpart(getline('.'), col('.') - 1) =~ '^\%(' . begin_pat . '\)'
		let flags .= 'c'
	endif
	let [lnum1, cnum1] = searchpairpos(begin_pat, '', end_pat, flags, 'LatexBox_InComment()')

	let env = ''

	if lnum1

		let line = strpart(getline(lnum1), cnum1 - 1)

		if empty(env)
			let env = matchstr(line, '^\C\\begin\_\s*{\zs[^}]*\ze}')
		endif
		if empty(env)
			let env = matchstr(line, '^\\\[')
		endif
		if empty(env)
			let env = matchstr(line, '^\\(')
		endif

	endif

	if with_pos == 1

		let flags = 'nW'
		if !(lnum1 == lnum && cnum1 == cnum)
			let flags .= 'c'
		endif

		let [lnum2, cnum2] = searchpairpos(begin_pat, '', end_pat, flags, 'LatexBox_InComment()')
		call setpos('.', saved_pos)
		return [env, lnum1, cnum1, lnum2, cnum2]
	else
		call setpos('.', saved_pos)
		return env
	endif


endfunction
" }}}


" Tex To Tree {{{
" stores nested braces in a tree structure
function! LatexBox_TexToTree(str)
	let tree = []
	let i1 = 0
	let i2 = -1
	let depth = 0
	while i2 < len(a:str)
		let i2 = match(a:str, '[{}]', i2 + 1)
		if i2 < 0
			let i2 = len(a:str)
		endif
		if i2 >= len(a:str) || a:str[i2] == '{'
			if depth == 0 
				let item = substitute(strpart(a:str, i1, i2 - i1), '^\s*\|\s*$', '', 'g')
				if !empty(item)
					call add(tree, item)
				endif
				let i1 = i2 + 1
			endif
			let depth += 1
		else
			let depth -= 1
			if depth == 0
				call add(tree, LatexBox_TexToTree(strpart(a:str, i1, i2 - i1)))
				let i1 = i2 + 1
			endif
		endif
	endwhile
	return tree
endfunction
" }}}

" Tree To Tex {{{
function! LatexBox_TreeToTex(tree)
	if type(a:tree) == type('')
		return a:tree
	else
		return '{' . join(map(a:tree, 'LatexBox_TreeToTex(v:val)'), '') . '}'
	endif
endfunction
" }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/complete.vim	[[[1
421
" LaTeX Box completion

" <SID> Wrap {{{
function! s:GetSID()
	return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
endfunction
let s:SID = s:GetSID()
function! s:SIDWrap(func)
	return s:SID . a:func
endfunction
" }}}


" Omni Completion {{{

let s:completion_type = ''

function! LatexBox_Complete(findstart, base)
	if a:findstart
		" return the starting position of the word
		let line = getline('.')
		let pos = col('.') - 1
		while pos > 0 && line[pos - 1] !~ '\\\|{'
			let pos -= 1
		endwhile

		let line_start = line[:pos-1]
		if line_start =~ '\C\\begin\_\s*{$'
			let s:completion_type = 'begin'
		elseif line_start =~ '\C\\end\_\s*{$'
			let s:completion_type = 'end'
		elseif line_start =~ g:LatexBox_ref_pattern . '$'
			let s:completion_type = 'ref'
		elseif line_start =~ g:LatexBox_cite_pattern . '$'
			let s:completion_type = 'bib'
			" check for multiple citations
			let pos = col('.') - 1
			while pos > 0 && line[pos - 1] !~ '{\|,'
				let pos -= 1
			endwhile
		else
			let s:completion_type = 'command'
			if line[pos - 1] == '\'
				let pos -= 1
			endif
		endif
		return pos
	else
		" return suggestions in an array
		let suggestions = []

		if s:completion_type == 'begin'
			" suggest known environments
			for entry in g:LatexBox_completion_environments
				if entry.word =~ '^' . escape(a:base, '\')
					if g:LatexBox_completion_close_braces && !s:NextCharsMatch('^}')
						" add trailing '}'
						let entry = copy(entry)
						let entry.abbr = entry.word
						let entry.word = entry.word . '}'
					endif
					call add(suggestions, entry)
				endif
			endfor
		elseif s:completion_type == 'end'
			" suggest known environments
			let env = LatexBox_GetCurrentEnvironment()
			if env != ''
				if g:LatexBox_completion_close_braces && !s:NextCharsMatch('^\s*[,}]')
					call add(suggestions, {'word': env . '}', 'abbr': env})
				else
					call add(suggestions, env)
				endif
			endif
		elseif s:completion_type == 'command'
			" suggest known commands
			for entry in g:LatexBox_completion_commands
				if entry.word =~ '^' . escape(a:base, '\')
					" do not display trailing '{'
					if entry.word =~ '{'
						let entry.abbr = entry.word[0:-2]
					endif
					call add(suggestions, entry)
				endif
			endfor
		elseif s:completion_type == 'ref'
			let suggestions = s:CompleteLabels(a:base)
		elseif s:completion_type == 'bib'
			" suggest BibTeX entries
			let suggestions = LatexBox_BibComplete(a:base)
		endif
		if !has('gui_running')
			redraw!
		endif
		return suggestions
	endif
endfunction
" }}}


" BibTeX search {{{

" find the \bibliography{...} commands
" the optional argument is the file name to be searched
function! LatexBox_kpsewhich(file)
	let old_dir = getcwd()
	execute 'lcd ' . fnameescape(LatexBox_GetTexRoot())
	redir => out
	silent execute '!kpsewhich ' . a:file
	redir END

	let out = split(out, "\<NL>")[-1]
	let out = substitute(out, '\r', '', 'g')
	let out = glob(fnamemodify(out, ':p'), 1)
	
	execute 'lcd ' . fnameescape(old_dir)

	return out
endfunction

function! s:FindBibData(...)

	if a:0 == 0
		let file = LatexBox_GetMainTexFile()
	else
		let file = a:1
	endif

	if empty(glob(file, 1))
		return ''
	endif

	let lines = readfile(file)

	let bibdata_list = []

	let bibdata_list +=
				\ map(filter(copy(lines), 'v:val =~ ''\C\\bibliography\s*{[^}]\+}'''),
				\ 'matchstr(v:val, ''\C\\bibliography\s*{\zs[^}]\+\ze}'')')

	let bibdata_list +=
				\ map(filter(copy(lines), 'v:val =~ ''\C\\\%(input\|include\)\s*{[^}]\+}'''),
				\ 's:FindBibData(LatexBox_kpsewhich(matchstr(v:val, ''\C\\\%(input\|include\)\s*{\zs[^}]\+\ze}'')))')

	let bibdata_list +=
				\ map(filter(copy(lines), 'v:val =~ ''\C\\\%(input\|include\)\s\+\S\+'''),
				\ 's:FindBibData(LatexBox_kpsewhich(matchstr(v:val, ''\C\\\%(input\|include\)\s\+\zs\S\+\ze'')))')

	let bibdata = join(bibdata_list, ',')

	return bibdata
endfunction

let s:bstfile = expand('<sfile>:p:h') . '/vimcomplete'

function! LatexBox_BibSearch(regexp)

	" find bib data
    let bibdata = s:FindBibData()
    if bibdata == ''
        echomsg 'error: no \bibliography{...} command found'
        return
    endif

    " write temporary aux file
	let tmpbase = LatexBox_GetTexRoot() . '/_LatexBox_BibComplete'
    let auxfile = tmpbase . '.aux'
    let bblfile = tmpbase . '.bbl'
    let blgfile = tmpbase . '.blg'

    call writefile(['\citation{*}', '\bibstyle{' . s:bstfile . '}', '\bibdata{' . bibdata . '}'], auxfile)

    silent execute '! cd ' shellescape(LatexBox_GetTexRoot()) .
				\ ' ; bibtex -terse ' . fnamemodify(auxfile, ':t') . ' >/dev/null'

    let res = []
    let curentry = ''

	let lines = split(substitute(join(readfile(bblfile), "\n"), '\n\n\@!\(\s\=\)\s*\|{\|}', '\1', 'g'), "\n")

    for line in filter(lines, 'v:val =~ a:regexp')
		let matches = matchlist(line, '^\(.*\)||\(.*\)||\(.*\)||\(.*\)||\(.*\)')
		if !empty(matches) && !empty(matches[1])
			call add(res, {'key': matches[1], 'type': matches[2],
						\ 'author': matches[3], 'year': matches[4], 'title': matches[5]})
		endif
    endfor

	call delete(auxfile)
	call delete(bblfile)
	call delete(blgfile)

	return res
endfunction
" }}}

" BibTeX completion {{{
function! LatexBox_BibComplete(regexp)

	" treat spaces as '.*' if needed
	if g:LatexBox_bibtex_wild_spaces
		"let regexp = substitute(a:regexp, '\s\+', '.*', 'g')
		let regexp = '.*' . substitute(a:regexp, '\s\+', '\\\&.*', 'g')
	else
		let regexp = a:regexp
	endif

    let res = []
    for m in LatexBox_BibSearch(regexp)

        let w = {'word': m['key'],
					\ 'abbr': '[' . m['type'] . '] ' . m['author'] . ' (' . m['year'] . ')',
					\ 'menu': m['title']}

		" close braces if needed
		if g:LatexBox_completion_close_braces && !s:NextCharsMatch('^\s*[,}]')
			let w.word = w.word . '}'
		endif

        call add(res, w)
    endfor
    return res
endfunction
" }}}

" Complete Labels {{{
" the optional argument is the file name to be searched
function! s:CompleteLabels(regex, ...)

	if a:0 == 0
		let file = LatexBox_GetAuxFile()
	else
		let file = a:1
	endif

	if empty(glob(file, 1))
		return []
	endif

	let suggestions = []

	" search for the target equation number
	for line in filter(readfile(file), 'v:val =~ ''^\\newlabel{\|^\\@input{''')

		echomsg "matching line: " . line

		" search for matching label
		let matches = matchlist(line, '^\\newlabel{\(' . a:regex . '[^}]*\)}{{\([^}]*\)}{\([^}]*\)}.*}')

		if empty(matches)
			" also try to match label and number
			let regex_split = split(a:regex)
			if len(regex_split) > 1
				let base = regex_split[0]
				let number = escape(join(regex_split[1:], ' '), '.')
				let matches = matchlist(line, '^\\newlabel{\(' . base . '[^}]*\)}{{\(' . number . '\)}{\([^}]*\)}.*}')
			endif
		endif

		if empty(matches)
			" also try to match number
			let matches = matchlist(line, '^\\newlabel{\([^}]*\)}{{\(' . escape(a:regex, '.') . '\)}{\([^}]*\)}.*}')
		endif

		if !empty(matches)

			let entry = {'word': matches[1], 'menu': '(' . matches[2] . ') [p.' . matches[3] . ']'}

			if g:LatexBox_completion_close_braces && !s:NextCharsMatch('^\s*[,}]')
				" add trailing '}'
				let entry = copy(entry)
				let entry.abbr = entry.word
				let entry.word = entry.word . '}'
			endif
			call add(suggestions, entry)
		endif

		" search for included files
		let included_file = matchstr(line, '^\\@input{\zs[^}]*\ze}')
		if included_file != ''
			let included_file = LatexBox_kpsewhich(included_file)
			call extend(suggestions, s:CompleteLabels(a:regex, included_file))
		endif
	endfor

	return suggestions

endfunction
" }}}


" Close Current Environment {{{
function! s:CloseCurEnv()
	" first, try with \left/\right pairs
	let [lnum, cnum] = searchpairpos('\C\\left\>', '', '\C\\right\>', 'bnW', 'LatexBox_InComment()')
	if lnum
		let line = strpart(getline(lnum), cnum - 1)
		let bracket = matchstr(line, '^\\left\zs\((\|\[\|\\{\||\|\.\)\ze')
		for [open, close] in [['(', ')'], ['\[', '\]'], ['\\{', '\\}'], ['|', '|'], ['\.', '|']]
			let bracket = substitute(bracket, open, close, 'g')
		endfor
		return '\right' . bracket
	endif
	
	" second, try with environments
	let env = LatexBox_GetCurrentEnvironment()
	if env == '\['
		return '\]'
	elseif env == '\('
		return '\)'
	elseif env != ''
		return '\end{' . env . '}'
	endif
	return ''
endfunction

" }}}

" Wrap Selection {{{
function! s:WrapSelection(wrapper)
	keepjumps normal! `>a}
	execute 'keepjumps normal! `<i\' . a:wrapper . '{'
endfunction
" }}}

" Wrap Selection in Environment with Prompt {{{
function! s:PromptEnvWrapSelection(...)
	let env = input('environment: ', '', 'customlist,' . s:SIDWrap('GetEnvironmentList'))
	if empty(env)
		return
	endif
	" LaTeXBox's custom indentation can interfere with environment
	" insertion when environments are indented (common for nested
	" environments).  Temporarily disable it for this operation:
	let ieOld = &indentexpr
	setlocal indentexpr=""
	if visualmode() ==# 'V'
		execute 'keepjumps normal! `>o\end{' . env . '}'
		execute 'keepjumps normal! `<O\begin{' . env . '}'
		" indent and format, if requested.
		if a:0 && a:1
			normal! gv>
			normal! gvgq
		endif
	else
		execute 'keepjumps normal! `>a\end{' . env . '}'
		execute 'keepjumps normal! `<i\begin{' . env . '}'
	endif
	exe "setlocal indentexpr=" . ieOld
endfunction
" }}}

" Change Environment {{{
function! s:ChangeEnvPrompt()

	let [env, lnum, cnum, lnum2, cnum2] = LatexBox_GetCurrentEnvironment(1)

	let new_env = input('change ' . env . ' for: ', '', 'customlist,' . s:SIDWrap('GetEnvironmentList'))
	if empty(new_env)
		return
	endif

	if new_env == '\[' || new_env == '['
		let begin = '\['
		let end = '\]'
	elseif new_env == '\(' || new_env == '('
		let begin = '\('
		let end = '\)'
	else
		let l:begin = '\begin{' . new_env . '}'
		let l:end = '\end{' . new_env . '}'
	endif
	
	if env == '\[' || env == '\('
		let line = getline(lnum2)
		let line = strpart(line, 0, cnum2 - 1) . l:end . strpart(line, cnum2 + 1)
		call setline(lnum2, line)

		let line = getline(lnum)
		let line = strpart(line, 0, cnum - 1) . l:begin . strpart(line, cnum + 1)
		call setline(lnum, line)
	else
		let line = getline(lnum2)
		let line = strpart(line, 0, cnum2 - 1) . l:end . strpart(line, cnum2 + len(env) + 5)
		call setline(lnum2, line)

		let line = getline(lnum)
		let line = strpart(line, 0, cnum - 1) . l:begin . strpart(line, cnum + len(env) + 7)
		call setline(lnum, line)
	endif

endfunction

function! s:GetEnvironmentList(lead, cmdline, pos)
	let suggestions = []
	for entry in g:LatexBox_completion_environments
		let env = entry.word
		if env =~ '^' . a:lead
			call add(suggestions, env)
		endif
	endfor
	return suggestions
endfunction
" }}}

" Next Charaters Match {{{
function! s:NextCharsMatch(regex)
	let rest_of_line = strpart(getline('.'), col('.') - 1)
	return rest_of_line =~ a:regex
endfunction
" }}}

" Mappings {{{
imap <silent> <Plug>LatexCloseCurEnv		<C-R>=<SID>CloseCurEnv()<CR>
vmap <silent> <Plug>LatexWrapSelection		:<c-u>call <SID>WrapSelection('')<CR>i
vmap <silent> <Plug>LatexEnvWrapSelection	:<c-u>call <SID>PromptEnvWrapSelection()<CR>
vmap <silent> <Plug>LatexEnvWrapFmtSelection	:<c-u>call <SID>PromptEnvWrapSelection(1)<CR>
nmap <silent> <Plug>LatexChangeEnv			:call <SID>ChangeEnvPrompt()<CR>
" }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/indent.vim	[[[1
79
" LaTeX indent file (part of LaTeX Box)
" Maintainer: David Munger (mungerd@gmail.com)

if exists("b:did_indent")
	finish
endif

let b:did_indent = 1

setlocal indentexpr=LatexBox_TexIndent()
setlocal indentkeys==\end,=\item,),],},o,0\\

let s:itemize_envs = ['itemize', 'enumerate', 'description']

" indent on \left( and on \(, but not on (
" indent on \left[ and on \[, but not on [
" indent on \left\{ and on \{, and on {
let s:open_pat = '\\begin\>\|\%(\\left\s*\)\=\\\=[{]\|\%(\\left\s*\|\\\)[[(]'
let s:close_pat = '\\end\>\|\%(\\right\s*\)\=\\\=[}]\|\%(\\right\s*\|\\\)[])]'


" Compute Level {{{
function! s:ComputeLevel(lnum_prev, open_pat, close_pat)

	let n = 0

	let line_prev = getline(a:lnum_prev)

	" strip comments
	let line_prev = substitute(line_prev, '\\\@<!%.*', '', 'g')

	" find unmatched opening patterns on previous line
	let n += len(substitute(substitute(line_prev, a:open_pat, "\n", 'g'), "[^\n]", '', 'g'))
	let n -= len(substitute(substitute(line_prev, a:close_pat, "\n", 'g'), "[^\n]", '', 'g'))

	" reduce indentation if current line starts with a closing pattern
	if getline(v:lnum) =~ '^\s*\%(' . a:close_pat . '\)'
		let n -= 1
	endif

	" compensate indentation if previous line starts with a closing pattern
	if line_prev =~ '^\s*\%(' . a:close_pat . '\)'
		let n += 1
	endif
	
	return n
endfunction
" }}}

" TexIndent {{{
function! LatexBox_TexIndent()

	let lnum_prev = prevnonblank(v:lnum - 1)

	if lnum_prev == 0
		return 0
	endif

	let n = 0

	let n += s:ComputeLevel(lnum_prev, s:open_pat, s:close_pat)

	let n += s:ComputeLevel(lnum_prev, '\\begin{\%(' . join(s:itemize_envs, '\|') . '\)}',
				\ '\\end{\%(' . join(s:itemize_envs, '\|') . '\)}')

	" less shift for lines starting with \item
	let item_here = getline(v:lnum) =~ '^\s*\\item'
	let item_above = getline(lnum_prev) =~ '^\s*\\item'
	if !item_here && item_above
		let n += 1
	elseif item_here && !item_above
		let n -= 1
	endif

	return indent(lnum_prev) + n * &sw
endfunction
" }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/latexmk.vim	[[[1
222
" LaTeX Box latexmk functions


" <SID> Wrap {{{
function! s:GetSID()
	return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
endfunction
let s:SID = s:GetSID()
function! s:SIDWrap(func)
	return s:SID . a:func
endfunction
" }}}


" dictionary of latexmk PID's (basename: pid)
let s:latexmk_running_pids = {}

" Set PID {{{
function! s:LatexmkSetPID(basename, pid)
	let s:latexmk_running_pids[a:basename] = a:pid
endfunction
" }}}

" Callback {{{
function! s:LatexmkCallback(basename, status)
	"let pos = getpos('.')
	if a:status
		echomsg "latexmk exited with status " . a:status
	else
		echomsg "latexmk finished"
	endif
	call remove(s:latexmk_running_pids, a:basename)
	call LatexBox_LatexErrors(g:LatexBox_autojump && a:status, a:basename)
	"call setpos('.', pos)
endfunction
" }}}

" Latexmk {{{
function! LatexBox_Latexmk(force)

	if empty(v:servername)
		echoerr "cannot run latexmk in background without a VIM server"
		return
	endif

	let basename = LatexBox_GetTexBasename(1)

	if has_key(s:latexmk_running_pids, basename)
		echomsg "latexmk is already running for `" . fnamemodify(basename, ':t') . "'"
		return
	endif

	let callsetpid = s:SIDWrap('LatexmkSetPID')
	let callback = s:SIDWrap('LatexmkCallback')

	let l:options = '-' . g:LatexBox_output_type . ' -quiet ' . g:LatexBox_latexmk_options
	if a:force
		let l:options .= ' -g'
	endif
	let l:options .= " -e '$pdflatex =~ s/ / -file-line-error /'"
	let l:options .= " -e '$latex =~ s/ / -file-line-error /'"

	" callback to set the pid
	let vimsetpid = g:vim_program . ' --servername ' . v:servername . ' --remote-expr ' .
				\ shellescape(callsetpid) . '\(\"' . fnameescape(basename) . '\",$$\)'

	" wrap width in log file
	let max_print_line = 2000

	" set environment
	if match(&shell, '/tcsh$') >= 0
		let l:env = 'setenv max_print_line ' . max_print_line . '; '
	else
		let l:env = 'max_print_line=' . max_print_line
	endif

	" latexmk command
	let cmd = 'cd ' . shellescape(LatexBox_GetTexRoot()) . ' ; ' . l:env .
				\ ' latexmk ' . l:options	. ' ' . shellescape(LatexBox_GetMainTexFile())

	" callback after latexmk is finished
	let vimcmd = g:vim_program . ' --servername ' . v:servername . ' --remote-expr ' . 
				\ shellescape(callback) . '\(\"' . fnameescape(basename) . '\",$?\)'

	silent execute '! ( ' . vimsetpid . ' ; ( ' . cmd . ' ) ; ' . vimcmd . ' ) >&/dev/null &'
	if !has("gui_running")
		redraw!
	endif
endfunction
" }}}

" LatexmkStop {{{
function! LatexBox_LatexmkStop()

	let basename = LatexBox_GetTexBasename(1)

	if !has_key(s:latexmk_running_pids, basename)
		echomsg "latexmk is not running for `" . fnamemodify(basename, ':t') . "'"
		return
	endif

	call s:kill_latexmk(s:latexmk_running_pids[basename])

	call remove(s:latexmk_running_pids, basename)
	echomsg "latexmk stopped for `" . fnamemodify(basename, ':t') . "'"
endfunction
" }}}

" kill_latexmk {{{
function! s:kill_latexmk(gpid)

	" This version doesn't work on systems on which pkill is not installed:
	"!silent execute '! pkill -g ' . pid

	" This version is more portable, but still doesn't work on Mac OS X:
	"!silent execute '! kill `ps -o pid= -g ' . pid . '`'

	" Since 'ps' behaves differently on different platforms, we must use brute force:
	" - list all processes in a temporary file
	" - match by process group ID
	" - kill matches
	let pids = []
	let tmpfile = tempname()
	silent execute '!ps x -o pgid,pid > ' . tmpfile
	for line in readfile(tmpfile)
		let pid = matchstr(line, '^\s*' . a:gpid . '\s\+\zs\d\+\ze')
		if !empty(pid)
			call add(pids, pid)
		endif
	endfor
	call delete(tmpfile)
	if !empty(pids)
		silent execute '! kill ' . join(pids)
	endif
endfunction
" }}}

" kill_all_latexmk {{{
function! s:kill_all_latexmk()
	for gpid in values(s:latexmk_running_pids)
		call s:kill_latexmk(gpid)
	endfor
	let s:latexmk_running_pids = {}
endfunction
" }}}

" LatexmkClean {{{
function! LatexBox_LatexmkClean(cleanall)

	if a:cleanall
		let l:options = '-C'
	else
		let l:options = '-c'
	endif

	silent execute '! cd ' . shellescape(LatexBox_GetTexRoot()) . ' ; latexmk ' . l:options
				\	. ' ' . shellescape(LatexBox_GetMainTexFile()) . ' >&/dev/null'
	if !has("gui_running")
		redraw!
	endif

	echomsg "latexmk clean finished"

endfunction
" }}}

" LatexmkStatus {{{
function! LatexBox_LatexmkStatus(detailed)

	if a:detailed
		if empty(s:latexmk_running_pids)
			echo "latexmk is not running"
		else
			let plist = ""
			for [basename, pid] in items(s:latexmk_running_pids)
				if !empty(plist)
					let plist .= '; '
				endif
				let plist .= fnamemodify(basename, ':t') . ':' . pid
			endfor
			echo "latexmk is running (" . plist . ")"
		endif
	else
		let basename = LatexBox_GetTexBasename(1)
		if has_key(s:latexmk_running_pids, basename)
			echo "latexmk is running"
		else
			echo "latexmk is not running"
		endif
	endif

endfunction
" }}}

" LatexErrors {{{
" LatexBox_LatexErrors(jump, [basename])
function! LatexBox_LatexErrors(jump, ...)
	if a:0 >= 1
		let log = a:1 . '.log'
	else
		let log = LatexBox_GetLogFile()
	endif

	if (a:jump)
		execute 'cfile ' . fnameescape(log)
	else
		execute 'cgetfile ' . fnameescape(log)
	endif
endfunction
" }}}

" Commands {{{
command! -buffer -bang	Latexmk				call LatexBox_Latexmk(<q-bang> == "!")
command! -buffer -bang	LatexmkClean		call LatexBox_LatexmkClean(<q-bang> == "!")
command! -buffer -bang	LatexmkStatus		call LatexBox_LatexmkStatus(<q-bang> == "!")
command! -buffer 		LatexmkStop			call LatexBox_LatexmkStop()
command! -buffer      	LatexErrors			call LatexBox_LatexErrors(1)
" }}}

autocmd VimLeavePre * call <SID>kill_all_latexmk()

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/mappings.vim	[[[1
58
" LaTeX Box mappings

if exists("g:LatexBox_no_mappings")
	finish
endif

" latexmk {{{
map <buffer> <LocalLeader>ll :Latexmk<CR>
map <buffer> <LocalLeader>lL :Latexmk!<CR>
map <buffer> <LocalLeader>lc :LatexmkClean<CR>
map <buffer> <LocalLeader>lC :LatexmkClean!<CR>
map <buffer> <LocalLeader>lg :LatexmkStatus<CR>
map <buffer> <LocalLeader>lG :LatexmkStatus!<CR>
map <buffer> <LocalLeader>lk :LatexmkStop<CR>
map <buffer> <LocalLeader>le :LatexErrors<CR>
" }}}

" View {{{
map <buffer> <LocalLeader>lv :LatexView<CR>
" }}}

" Error Format {{{
" This assumes we're using the -file-line-error with [pdf]latex.
setlocal efm=%E%f:%l:%m,%-Cl.%l\ %m,%-G
" }}}

" TOC {{{
command! LatexTOC call LatexBox_TOC()
map <silent> <buffer> <LocalLeader>lt :LatexTOC<CR>
" }}}

" begin/end pairs {{{
nmap <buffer> % <Plug>LatexBox_JumpToMatch
xmap <buffer> % <Plug>LatexBox_JumpToMatch
vmap <buffer> ie <Plug>LatexBox_SelectCurrentEnvInner
vmap <buffer> ae <Plug>LatexBox_SelectCurrentEnvOuter
omap <buffer> ie :normal vie<CR>
omap <buffer> ae :normal vae<CR>
vmap <buffer> i$ <Plug>LatexBox_SelectInlineMathInner
vmap <buffer> a$ <Plug>LatexBox_SelectInlineMathOuter
omap <buffer> i$ :normal vi$<CR>
omap <buffer> a$ :normal va$<CR>
" }}}

setlocal omnifunc=LatexBox_Complete

finish

" Suggested mappings:

" Motion {{{
map <silent> <buffer> ¶ :call LatexBox_JumpToNextBraces(0)<CR>
map <silent> <buffer> § :call LatexBox_JumpToNextBraces(1)<CR>
imap <silent> <buffer> ¶ <C-R>=LatexBox_JumpToNextBraces(0)<CR>
imap <silent> <buffer> § <C-R>=LatexBox_JumpToNextBraces(1)<CR>
" }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/motion.vim	[[[1
481
" LaTeX Box motion functions

" HasSyntax {{{
" s:HasSyntax(syntaxName, [line], [col])
function! s:HasSyntax(syntaxName, ...)
	let line	= a:0 >= 1 ? a:1 : line('.')
	let col		= a:0 >= 2 ? a:2 : col('.')
	return index(map(synstack(line, col), 'synIDattr(v:val, "name") == "' . a:syntaxName . '"'), 1) >= 0
endfunction
" }}}

" Search and Skip Comments {{{
" s:SearchAndSkipComments(pattern, [flags], [stopline])
function! s:SearchAndSkipComments(pat, ...)
	let flags		= a:0 >= 1 ? a:1 : ''
	let stopline	= a:0 >= 2 ? a:2 : 0
	let saved_pos = getpos('.')

	" search once
	let ret = search(a:pat, flags, stopline)

	if ret
		" do not match at current position if inside comment
		let flags = substitute(flags, 'c', '', 'g')

		" keep searching while in comment
		while LatexBox_InComment()
			let ret = search(a:pat, flags, stopline)
			if !ret
				break
			endif
		endwhile
	endif

	if !ret
		" if no match found, restore position
		call setpos('.', saved_pos)
	endif

	return ret
endfunction
" }}}

" begin/end pairs {{{
"
" s:JumpToMatch(mode, [backward])
" - search backwards if backward is given and nonzero
" - search forward otherwise
"
function! s:JumpToMatch(mode, ...)

	if a:0 >= 1
		let backward = a:1
	else
		let backward = 0
	endif

	let sflags = backward ? 'cbW' : 'cW'

	" selection is lost upon function call, reselect
	if a:mode == 'v'
		normal! gv
	endif

	" open/close pairs (dollars signs are treated apart)
	let open_pats  = ['{', '\[', '(', '\\begin\>', '\\left\>', '\\lceil\>', '\\lgroup\>', '\\lfloor', '\\langle']
	let close_pats = ['}', '\]', ')', '\\end\>', '\\right\>', '\\rceil', '\\rgroup\>', '\\rfloor', '\\rangle']
	let dollar_pat = '\\\@<!\$'

	let saved_pos = getpos('.')

	" move to the left until not on alphabetic characters
	call search('\A', 'cbW', line('.'))

	" go to next opening/closing pattern on same line
	if !s:SearchAndSkipComments(
				\	'\m\C\%(' . join(open_pats + close_pats + [dollar_pat], '\|') . '\)',
				\	sflags, line('.'))
		" abort if no match or if match is inside a comment
		call setpos('.', saved_pos)
		return
	endif

	let rest_of_line = strpart(getline('.'), col('.') - 1)

	" match for '$' pairs
	if rest_of_line =~ '^\$'

		" check if next character is in inline math
		let [lnum, cnum] = searchpos('.', 'nW')
		if lnum && s:HasSyntax('texMathZoneX', lnum, cnum)
			call s:SearchAndSkipComments(dollar_pat, 'W')
		else
			call s:SearchAndSkipComments(dollar_pat, 'bW')
		endif

	else

		" match other pairs
		for i in range(len(open_pats))
			let open_pat = open_pats[i]
			let close_pat = close_pats[i]

			if rest_of_line =~ '^\C\%(' . open_pat . '\)'
				" if on opening pattern, go to closing pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'W', 'LatexBox_InComment()')
				break
			elseif rest_of_line =~ '^\C\%(' . close_pat . '\)'
				" if on closing pattern, go to opening pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'bW', 'LatexBox_InComment()')
				break
			endif

		endfor
	endif

endfunction

nnoremap <silent> <Plug>LatexBox_JumpToMatch		:call <SID>JumpToMatch('n')<CR>
vnoremap <silent> <Plug>LatexBox_JumpToMatch		:<C-U>call <SID>JumpToMatch('v')<CR>
nnoremap <silent> <Plug>LatexBox_BackJumpToMatch	:call <SID>JumpToMatch('n', 1)<CR>
vnoremap <silent> <Plug>LatexBox_BackJumpToMatch	:<C-U>call <SID>JumpToMatch('v', 1)<CR>
" }}}

" select inline math {{{
" s:SelectInlineMath(seltype)
" where seltype is either 'inner' or 'outer'
function! s:SelectInlineMath(seltype)

	let dollar_pat = '\\\@<!\$'

	if s:HasSyntax('texMathZoneX')
		call s:SearchAndSkipComments(dollar_pat, 'cbW')
	elseif getline('.')[col('.') - 1] == '$'
		call s:SearchAndSkipComments(dollar_pat, 'bW')
	else
		return
	endif

	if a:seltype == 'inner'
		normal! l
	endif

	if visualmode() ==# 'V'
		normal! V
	else
		normal! v
	endif

	call s:SearchAndSkipComments(dollar_pat, 'W')

	if a:seltype == 'inner'
		normal! h
	endif
endfunction

vnoremap <silent> <Plug>LatexBox_SelectInlineMathInner :<C-U>call <SID>SelectInlineMath('inner')<CR>
vnoremap <silent> <Plug>LatexBox_SelectInlineMathOuter :<C-U>call <SID>SelectInlineMath('outer')<CR>
" }}}

" select current environment {{{
function! s:SelectCurrentEnv(seltype)
	let [env, lnum, cnum, lnum2, cnum2] = LatexBox_GetCurrentEnvironment(1)
	call cursor(lnum, cnum)
	if a:seltype == 'inner'
		if env =~ '^\'
			call search('\\.\_\s*\S', 'eW')
		else
			call search('}\(\_\s*\[\_[^]]*\]\)\?\_\s*\S', 'eW')
		endif
	endif
	if visualmode() ==# 'V'
		normal! V
	else
		normal! v
	endif
	call cursor(lnum2, cnum2)
	if a:seltype == 'inner'
		call search('\S\_\s*', 'bW')
	else
		if env =~ '^\'
			normal! l
		else
			call search('}', 'eW')
		endif
	endif
endfunction
vnoremap <silent> <Plug>LatexBox_SelectCurrentEnvInner :<C-U>call <SID>SelectCurrentEnv('inner')<CR>
vnoremap <silent> <Plug>LatexBox_SelectCurrentEnvOuter :<C-U>call <SID>SelectCurrentEnv('outer')<CR>
" }}}

" Jump to the next braces {{{
"
function! LatexBox_JumpToNextBraces(backward)
	let flags = ''
	if a:backward
		normal h
		let flags .= 'b'
	else
		let flags .= 'c'
	endif
	if search('[][}{]', flags) > 0
		normal l
	endif
	let prev = strpart(getline('.'), col('.') - 2, 1)
	let next = strpart(getline('.'), col('.') - 1, 1)
	if next =~ '[]}]' && prev !~ '[][{}]'
		return "\<Right>"
	else
		return ''
	endif
endfunction
" }}}

" Table of Contents {{{
function! s:ReadTOC(auxfile)

	let toc = []

	let prefix = fnamemodify(a:auxfile, ':p:h')

	for line in readfile(a:auxfile)

		let included = matchstr(line, '^\\@input{\zs[^}]*\ze}')
		
		if included != ''
			call extend(toc, s:ReadTOC(prefix . '/' . included))
			continue
		endif

		" Parse lines like:
		" \@writefile{toc}{\contentsline {section}{\numberline {secnum}Section Title}{pagenumber}}
		" \@writefile{toc}{\contentsline {section}{\tocsection {}{1}{Section Title}}{pagenumber}}
		" \@writefile{toc}{\contentsline {section}{\numberline {secnum}Section Title}{pagenumber}{otherstuff}}

		let line = matchstr(line, '^\\@writefile{toc}{\\contentsline\s*\zs.*\ze}\s*$')
		if empty(line)
			continue
		endif

		let tree = LatexBox_TexToTree(line)

		if len(tree) < 3
			" unknown entry type: just skip it
			continue
		endif

		" parse level
		let level = tree[0][0]
		" parse page
		if !empty(tree[2])
			let page = tree[2][0]
		else
			let page = ''
		endif
		" parse section number
		if len(tree[1]) > 3 && empty(tree[1][1])
			call remove(tree[1], 1)
		endif
		let secnum = ""
		if len(tree[1]) > 1
			if !empty(tree[1][1])
				let secnum = tree[1][1][0]
			endif
			let tree = tree[1][2:]
		else
			let secnum = ''
			let tree = tree[1]
		endif
		" parse section title
		let text = LatexBox_TreeToTex(tree)
		let text = substitute(text, '^{\+\|}\+$', '', 'g')

		" add TOC entry
		call add(toc, {'file': bufname('%'),
					\ 'level': level, 'number': secnum, 'text': text, 'page': page})
	endfor

	return toc

endfunction

function! LatexBox_TOC()

	" check if window already exists
	let winnr = bufwinnr(bufnr('LaTeX TOC'))
	if winnr >= 0
		silent execute winnr . 'wincmd w'
		return
	endif

	" read TOC
	let toc = s:ReadTOC(LatexBox_GetAuxFile())
	let calling_buf = bufnr('%')

	" find closest section in current buffer
	let closest_index = s:FindClosestSection(toc)

	execute g:LatexBox_split_width . 'vnew LaTeX\ TOC'
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline nonumber

	for entry in toc
		call append('$', entry['number'] . "\t" . entry['text'])
	endfor
	call append('$', ["", "<Esc>/q: close", "<Space>: jump", "<Enter>: jump and close"])

	0delete

	" syntax
	syntax match helpText /^<.*/
	syntax match secNum /^\S\+/ contained
	syntax match secLine /^\S\+\t\S\+/ contains=secNum
	syntax match mainSecLine /^[^\.]\+\t.*/ contains=secNum
	syntax match ssubSecLine /^[^\.]\+\.[^\.]\+\.[^\.]\+\t.*/ contains=secNum
	highlight link helpText		PreProc
	highlight link secNum		Number
	highlight link mainSecLine	Title
	highlight link ssubSecLine	Comment

	map <buffer> <silent> q			:bwipeout<CR>
	map <buffer> <silent> <Esc>		:bwipeout<CR>
	map <buffer> <silent> <Space> 	:call <SID>TOCActivate(0)<CR>
	map <buffer> <silent> <CR> 		:call <SID>TOCActivate(1)<CR>
    nnoremap <silent> <buffer> <leftrelease> :call <SID>TOCActivate(0)<cr>
    nnoremap <silent> <buffer> <2-leftmouse> :call <SID>TOCActivate(1)<cr>
	nnoremap <buffer> <silent> G	G4k

	setlocal nomodifiable tabstop=8

	let b:toc = toc
	let b:calling_win = bufwinnr(calling_buf)

	" jump to closest section
	execute 'normal! ' . (closest_index + 1) . 'G'

endfunction

" Binary search for the closest section
" return the index of the TOC entry
function! s:FindClosestSection(toc)
	let imax = len(a:toc)
	let imin = 0
	while imin < imax - 1
		let i = (imax + imin) / 2
		let entry = a:toc[i]
		let titlestr = entry['text']
		let titlestr = escape(titlestr, '\')
		let titlestr = substitute(titlestr, ' ', '\\_\\s\\+', 'g')
		let [lnum, cnum] = searchpos('\\' . entry['level'] . '\_\s*{' . titlestr . '}', 'nW')
		if lnum
			let imax = i
		else
			let imin = i
		endif
	endwhile

	return imin
endfunction

function! s:TOCActivate(close)
	let n = getpos('.')[1] - 1

	if n >= len(b:toc)
		return
	endif

	let entry = b:toc[n]

	let toc_bnr = bufnr('%')
	let toc_wnr = winnr()

	execute b:calling_win . 'wincmd w'

	let bnr = bufnr(entry['file'])
	if bnr >= 0
		execute 'buffer ' . bnr
	else
		execute 'edit ' . entry['file']
	endif

	let titlestr = entry['text']

	" Credit goes to Marcin Szamotulski for the following fix. It allows to match through
	" commands added by TeX.
	let titlestr = substitute(titlestr, '\\\w*\>\s*\%({[^}]*}\)\?', '.*', 'g')

	let titlestr = escape(titlestr, '\')
	let titlestr = substitute(titlestr, ' ', '\\_\\s\\+', 'g')

	if search('\\' . entry['level'] . '\_\s*{' . titlestr . '}', 'ws')
		normal zt
	endif

	if a:close
		execute 'bwipeout ' . toc_bnr
	else
		execute toc_wnr . 'wincmd w'
	endif
endfunction
" }}}

" Highlight Matching Pair {{{
function! s:HighlightMatchingPair()

	2match none

	if LatexBox_InComment()
		return
	endif

	let open_pats = ['\\begin\>', '\\left\>']
	let close_pats = ['\\end\>', '\\right\>']
	let dollar_pat = '\\\@<!\$'

	let saved_pos = getpos('.')

	if getline('.')[col('.') - 1] == '$'

	   if strpart(getline('.'), col('.') - 2, 1) == '\'
		   return
	   endif

		" match $-pairs
		let lnum = line('.')
		let cnum = col('.')
	
		" check if next character is in inline math
		let [lnum2, cnum2] = searchpos('.', 'nW')
		if lnum2 && s:HasSyntax('texMathZoneX', lnum2, cnum2)
			call s:SearchAndSkipComments(dollar_pat, 'W')
		else
			call s:SearchAndSkipComments(dollar_pat, 'bW')
		endif

		execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum . 'c\$'
					\	. '\|\%' . line('.') . 'l\%' . col('.') . 'c\$\)/'

	else
		" match other pairs

		" find first non-alpha character to the left on the same line
		let [lnum, cnum] = searchpos('\A', 'cbW', line('.'))

		let delim = matchstr(getline(lnum), '^\m\(' . join(open_pats + close_pats, '\|') . '\)', cnum - 1)

		if empty(delim)
			call setpos('.', saved_pos)
			return
		endif

		for i in range(len(open_pats))
			let open_pat = open_pats[i]
			let close_pat = close_pats[i]

			if delim =~# '^' . open_pat
				" if on opening pattern, go to closing pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'W', 'LatexBox_InComment()')
				execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum . 'c' . open_pats[i]
							\	. '\|\%' . line('.') . 'l\%' . col('.') . 'c' . close_pats[i] . '\)/'
				break
			elseif delim =~# '^' . close_pat
				" if on closing pattern, go to opening pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'bW', 'LatexBox_InComment()')
				execute '2match MatchParen /\%(\%' . line('.') . 'l\%' . col('.') . 'c' . open_pats[i]
							\	. '\|\%' . lnum . 'l\%' . cnum . 'c' . close_pats[i] . '\)/'
				break
			endif
		endfor
	endif

	call setpos('.', saved_pos)
endfunction
" }}}

augroup LatexBox_HighlightPairs
  " Replace all matchparen autocommands
  autocmd! CursorMoved *.tex call s:HighlightMatchingPair()
  autocmd! CursorMovedi *.tex call s:HighlightMatchingPair()
augroup END

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
ftplugin/latex-box/vimcomplete.bst	[[[1
306
ENTRY
  { address author booktitle chapter doi edition editor eid howpublished institution isbn issn journal key month note number organization pages publisher school series title type volume year }
  {}
  { label }
STRINGS { s t}

FUNCTION {output}
{ 's :=
  %purify$
  %"}{" * write$
  "||" * write$
  s
}
FUNCTION {fin.entry}
%{ "}" * write$
{ write$
  newline$
}

FUNCTION {not}
{   { #0 }
    { #1 }
  if$
}
FUNCTION {and}
{   'skip$
    { pop$ #0 }
  if$
}
FUNCTION {or}
{   { pop$ #1 }
    'skip$
  if$
}
FUNCTION {field.or.null}
{ duplicate$ empty$
    { pop$ "" }
    'skip$
  if$
}

FUNCTION {capitalize}
{ "u" change.case$ "t" change.case$ }

FUNCTION {space.word}
{ " " swap$ * " " * }

FUNCTION {bbl.and}      { "&"}
FUNCTION {bbl.etal}     { "et al." }

INTEGERS { nameptr namesleft numnames }

STRINGS  { bibinfo}

FUNCTION {format.names}
{ duplicate$ empty$ 'skip$ {
  's :=
  "" 't :=
  #1 'nameptr :=
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    { s nameptr
      %"{vv~}{ll}{, f.}{, jj}"
      "{vv }{ll}{}{}"
      format.name$
      't :=
      nameptr #1 >
        {
          namesleft #1 >
            { ", " * t * }
            {
              s nameptr "{ll}" format.name$ duplicate$ "others" =
                { 't := }
                { pop$ }
              if$
              t "others" =
                {
                  " " * bbl.etal *
                }
                {
                  bbl.and
                  space.word * t *
                }
              if$
            }
          if$
        }
        't
      if$
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
  } if$
}

FUNCTION {format.authors}
{ author empty$
    {editor format.names} {author format.names}
  if$
}

FUNCTION {format.title}
{ title
  duplicate$ empty$ 'skip$
    { "t" change.case$ }
  if$
}
FUNCTION {output.label}
{ newline$
  %"{" cite$ * write$
  cite$ write$
  ""
}


FUNCTION {format.date}
{
  ""
  duplicate$ empty$
  year  duplicate$ empty$
    { swap$ 'skip$
        { "there's a month but no year in " cite$ * warning$ }
      if$
      *
    }
    { swap$ 'skip$
        {
          swap$
          " " * swap$
        }
      if$
      *
    }
  if$
}

FUNCTION {output.entry}
{ 's :=
  output.label
  s output
  format.authors output
  format.date output
  format.title output
  fin.entry
}

FUNCTION {default.type}     {"?" output.entry}

FUNCTION {article}          {"a" output.entry}
FUNCTION {book}             {"B" output.entry}
FUNCTION {booklet}          {"k" output.entry}
FUNCTION {conference}       {"f" output.entry}
FUNCTION {inbook}           {"b" output.entry}
FUNCTION {incollection}     {"c" output.entry}
FUNCTION {inproceedings}    {"p" output.entry}
FUNCTION {manual}           {"m" output.entry}
FUNCTION {mastersthesis}    {"Master" output.entry}
FUNCTION {misc}             {"-" output.entry}
FUNCTION {phdthesis}        {"PhD" output.entry}
FUNCTION {proceedings}      {"P" output.entry}
FUNCTION {techreport}       {"r" output.entry}
FUNCTION {unpublished}      {"u" output.entry}


READ
FUNCTION {sortify}
{ purify$
  "l" change.case$
}
INTEGERS { len }
FUNCTION {chop.word}
{ 's :=
  'len :=
  s #1 len substring$ =
    { s len #1 + global.max$ substring$ }
    's
  if$
}
FUNCTION {sort.format.names}
{ 's :=
  #1 'nameptr :=
  ""
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    { s nameptr
      "{vv{ } }{ll{ }}{  f{ }}{  jj{ }}"
      format.name$ 't :=
      nameptr #1 >
        {
          "   "  *
          namesleft #1 = t "others" = and
            { "zzzzz" * }
            { t sortify * }
          if$
        }
        { t sortify * }
      if$
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
}

FUNCTION {sort.format.title}
{ 't :=
  "A " #2
    "An " #3
      "The " #4 t chop.word
    chop.word
  chop.word
  sortify
  #1 global.max$ substring$
}
FUNCTION {author.sort}
{ author empty$
    { key empty$
        { "to sort, need author or key in " cite$ * warning$
          ""
        }
        { key sortify }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {author.editor.sort}
{ author empty$
    { editor empty$
        { key empty$
            { "to sort, need author, editor, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { editor sort.format.names }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {author.organization.sort}
{ author empty$
    { organization empty$
        { key empty$
            { "to sort, need author, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {editor.organization.sort}
{ editor empty$
    { organization empty$
        { key empty$
            { "to sort, need editor, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { editor sort.format.names }
  if$
}
FUNCTION {presort}
{ type$ "book" =
  type$ "inbook" =
  or
    'author.editor.sort
    { type$ "proceedings" =
        'editor.organization.sort
        { type$ "manual" =
            'author.organization.sort
            'author.sort
          if$
        }
      if$
    }
  if$
  "    "
  *
  year field.or.null sortify
  *
  "    "
  *
  title field.or.null
  sort.format.title
  *
  #1 entry.max$ substring$
  'sort.key$ :=
}
ITERATE {presort}
SORT
ITERATE {call.type$}
doc/latex-box.txt	[[[1
436
*latex-box.txt*  	LaTeX Box
*latex-box*

This plugin consists of a set of tools to help editing LaTeX documents.

Manifesto: LaTeX Box aims to remain lightweight and stay out of the way.

This plugin provides:
- Background compilation using latexmk;
- Completion for commands, environments, labels, and bibtex entries;
- A simple table of contents;
- Smart indentation (activated with "set smartindent");
- Highlighting of matching \begin/\end pairs
- Motion between matching \begin/\end pairs with the % key;
- Motion through brackets/braces (with user-defined keys).
- Environment objects (e.g., select environement with "vie" or "vae")
- Inline math objects (e.g., select inline math with "vi$" or "va$")

==============================================================================

|latex-box-completion|			COMPLETION
|latex-box-completion-commands|		Commands
|latex-box-completion-environments|	Environments
|latex-box-completion-labels|		Labels
|latex-box-completion-bibtex|		Bibtex

|latex-box-commands|			COMMANDS
|latex-box-commands-compilation|	Compilation
|latex-box-commands-viewing|		Viewing
|latex-box-commands-motion|		Motion

|latex-box-motion|			MOTION

|latex-box-mappings|			MAPPINGS
|latex-box-mappings-compilation|	Compilation
|latex-box-mappings-insertion|		Insertion
|latex-box-mappings-viewing|		Viewing
|latex-box-mappings-motion|		Motion

|latex-box-settings|			SETTINGS
|latex-box-settings-compilation|	Compilation
|latex-box-settings-completion|		Completion
|latex-box-settings-windows|		Vim Windows

|latex-box-FAQ|				Frequently Asked Questions

==============================================================================

COMPLETION						*latex-box-completion*

Completion is achieved through omni completion |compl-omni|, with default
bindings <CTRL-X><CTRL-O>. There are four types of completion:



------------------------------------------------------------------------------

						*latex-box-completion-commands*
Commands ~

Command completion is triggered by the '\' character.  For example, >
	\beg<CTRL-X><CTRL-O>
completes to >
	\begin{

Associated settings:
	|g:LatexBox_completion_commands|
	|g:LatexBox_completion_close_braces|


------------------------------------------------------------------------------

						*latex-box-completion-environments*
Environments ~

Environment completion is triggered by '\begin{'.  For example, >
	\begin{it<CTRL-X><CTRL-O>
completes to >
	\begin{itemize}

Completion of '\end{' automatically closes the last open environment.

Associated settings:
	|g:LatexBox_completion_environments|
	|g:LatexBox_completion_close_braces|


------------------------------------------------------------------------------

						*latex-box-completion-labels*
Labels ~

Label completion is triggered by '\ref{' or '\eqref{'.  For example, >
	\ref{sec:<CTRL-X><CTRL-O>
offers a list of all matching labels, with their associated value and page number.
Labels are read from the aux file, so label completion works only after
complilation.

It matches:
	1. labels: >
		\ref{sec:<CTRL-X><CTRL-O>
<	2. numbers: >
		\eqref{2<CTRL-X><CTRL-O>
<	3. labels and numbers together (separated by whitespace): >
		\eqref{eq 2<CTRL-X><CTRL-O>
	

Associated settings:
	|g:LatexBox_ref_pattern|
	|g:LatexBox_completion_close_braces|


------------------------------------------------------------------------------

						*latex-box-completion-bibtex*
BibTeX entries ~

BibTeX completion is triggered by '\cite{', '\citep{' or '\citet{'.
For example, assume you have in your .bib files an entry looking like: >

	@book {	knuth1981,
		author = "Donald E. Knuth",
		title = "Seminumerical Algorithms",
		publisher = "Addison-Wesley",
		year = "1981" }

Then, try: >

	\cite{Knuth 1981<CTRL-X><CTRL-O>
	\cite{algo<CTRL-X><CTRL-O>

You can also use regular expressions (or vim patterns) after '\cite{'.

Associated settings:
	|g:LatexBox_cite_pattern|
	|g:LatexBox_bibtex_wild_spaces|
	|g:LatexBox_completion_close_braces|


==============================================================================

COMMANDS						*latex-box-commands*

------------------------------------------------------------------------------

							*latex-box-commands-compilation*
Compilation ~

*:Latexmk*
	Compile with latexmk in background.
	See |g:LatexBox_latexmk_options|.
*:LatexmkForce*
	Force compilation with latexmk in background.
*:LatexmkClean*
	Clean temporary output from LaTeX.
*:LatexmkCleanAll*
	Clean all output from LaTeX.
*:LatexmkStop*
	Stop latexmk if it is running.
*:LatexmkStatus*
	Show the running status of latexmk for the current buffer.
*:LatexmkStatusDetailed*
	Show the running status of latexmk for all buffers with process group
	ID's.
*:LatexErrors*
	Load the log file for the current document and jump to the first error.

When latexmk terminates, it reports its success or failure (with status
number). To navigate through the errors, you can use the |:cc|, |:cn| and
|:cp| commands, as well as the |:clist| command to list the errors.

------------------------------------------------------------------------------

							*latex-box-commands-viewing*
Viewing ~

*:LatexView*
	Launch viewer on output file.
	See |g:LatexBox_output_type| and |g:LatexBox_viewer|.

------------------------------------------------------------------------------

							*latex-box-commands-motion*
Motion ~

*:LatexTOC*
	Open a table of contents.
	Use Enter to navigate to selected entry.
	See |g:LatexBox_split_width|.



==============================================================================

MOTION							*latex-box-motion*

The function LatexBox_JumpToNextBraces({backward}) allows to jump outside of
the current brace/bracket pair, or inside of the next opening braces/brackets.


==============================================================================

MAPPINGS						*latex-box-mappings*

------------------------------------------------------------------------------

							*latex-box-mappings-compilation*
Compilation ~

<LocalLeader>ll		|:Latexmk|
	Compile with latexmk in background.
<LocalLeader>lL		|:LatexmkForce|
	Force compilation with latexmk in background.
<LocalLeader>lc		|:LatexmkClean|
	Clean temporary output from LaTeX.
<LocalLeader>lC		|:LatexmkCleanAll|
	Clean all output from LaTeX.
<LocalLeader>lk		|:LatexmkStop|
	Stop latexmk if it is running.
<LocalLeader>lg		|:LatexmkStatus|
	Show the running status of latexmk for the current buffer.
<LocalLeader>lG		|:LatexmkStatusDetailed|
	Show the running status of latexmk for all buffers with process group
	ID's.
<LocalLeader>le		|:LatexErrors|
	Load the log file for the current document and jump to the first error.


------------------------------------------------------------------------------

							*latex-box-mappings-viewing*
Viewing ~

<LocalLeader>lv		|:LatexView|
	View output file.

------------------------------------------------------------------------------

							*latex-box-mappings-insertion*
Insertion ~


*<Plug>LatexCloseCurEnv*
	Close the last matching open environment. Use with imap, e.g.: >
	imap ]]		<Plug>LatexCloseCurEnv
<
*<Plug>LatexChangeEnv*
	Change the current environment. Use with nmap, e.g.: >
	nmap <F5>		<Plug>LatexChangeEnv
<
*<Plug>LatexWrapSelection*
	Wrap the current selection in a LaTeX command. Use with vmap, e.g.: >
	vmap <F7>		<Plug>LatexWrapSelection
<
*<Plug>LatexEnvWrapSelection*
	Wrap the current selection in an environment. Use with vmap, e.g.: >
	vmap <S-F7>		<Plug>LatexEnvWrapSelection
<
Suggested mappings to put in ~/.vim/ftplugin/tex.vim: >
	imap <buffer> [[ 		\begin{
	imap <buffer> ]]		<Plug>LatexCloseCurEnv
	nmap <buffer> <F5>		<Plug>LatexChangeEnv
	vmap <buffer> <F7>		<Plug>LatexWrapSelection
	vmap <buffer> <S-F7>		<Plug>LatexEnvWrapSelection
	imap <buffer> (( 		\eqref{
<
------------------------------------------------------------------------------

							*latex-box-mappings-motion*
Motion ~

<LocalLeader>lt		|:LatexTOC|
	Open a table of contents.
	Use Enter to navigate to selected entry.

*<Plug>LatexBox_JumpToMatch*
	Jump to the matching bracket or \begin/\end pairs. Emulates |%|.

*<Plug>LatexBox_BackJumpToMatch*
	Same as |<Plug>LatexBox_JumpToMatch|, but the initial search is backward.

Suggested bindings: >
	map  <silent> <buffer> ¶ :call LatexBox_JumpToNextBraces(0)<CR>
	map  <silent> <buffer> § :call LatexBox_JumpToNextBraces(1)<CR>
	imap <silent> <buffer> ¶ <C-R>=LatexBox_JumpToNextBraces(0)<CR>
	imap <silent> <buffer> § <C-R>=LatexBox_JumpToNextBraces(1)<CR>
<

==============================================================================

SETTINGS						*latex-box-settings*


------------------------------------------------------------------------------

Mappings ~

*g:LatexBox_no_mappings*
	If this variable is defined, the default keyboard mappings will not be
	loaded.


						*latex-box-settings-completion*
Completion ~

*g:LatexBox_completion_close_braces*	Default: 1

	If nonzero, omni completion will add closing brackets where relevant.
	For example, if nonzero, >
		\begin{itemize
<	completes to >
		\begin{itemize}

*g:LatexBox_bibtex_wild_spaces*		Default: 1

	If nonzero, spaces act as wildcards ('.*') in completion.
	For example, if nonzero, >
		\cite{Knuth 1981
<	is equivalent to >
		\cite{Knuth.*1981

*g:LatexBox_completion_environments*
*g:LatexBox_completion_commands*

	Static completion lists for environments
	|latex-box-completion-environments| and commands
	|latex-box-completion-commands|.
	See |complete-items|.

*g:LatexBox_cite_pattern*		Default: '\\cite\(p\|t\)\?\*\?\_\s*{'
*g:LatexBox_ref_pattern*		Default: '\\v\?\(eq\|page\)\?ref\*\?\_\s*{'

	Patterns to match \cite and \ref commands for BibTeX and label completion.
	Must include the trailing '{'.
	To match all commands that contain 'cite' (case insensitive), use: >
		let LatexBox_cite_pattern = '\c\\\a*cite\a*\*\?\_\s*{'
<	To match all commands that end with 'ref' (case insensitive): >
		let LatexBox_ref_pattern = '\c\\\a*ref\*\?\_\s*{'
<	Both examples match commands with a trailing star too.


------------------------------------------------------------------------------

Templates (DEPRECATED) ~

*g:LatexBox_templates*

	Dictionary of environment templates |latex-box-templates|.
	
	DEPRECATED!
	I think it is better to leave this task to plug-ins oriented to do
	this well, like snipMate:
	http://www.vim.org/scripts/script.php?script_id=2540

	


------------------------------------------------------------------------------

						*latex-box-settings-compilation*
Compilation ~

*g:vim_program*			Default: autodetected

	Vim program to use on command line for callbacks.
	If autodetect fails, defaults to >
	'/Applications/MacVim.app/Contents/MacOS/Vim -g'
<	on MacVim, or to |v:progname| on other systems.

*g:LatexBox_latexmk_options*	Default: ""

	Additional options to pass to latexmk during compilation, e.g, "-d".

*g:LatexBox_output_type*	Default: "pdf"

	Extension of the output file. One of "pdf", "dvi" or "ps".

*g:LatexBox_viewer*		Default: "xdg-open"

	Viewer application for the output file, e.g., "xpdf".

*g:LatexBox_autojump*		Default: 0

	Automatically jump to first error after calling latexmk.

*b:main_tex_file*		Default: ""

	Path to the main LaTeX file associated to the current buffer.
	When editing a LaTeX document consisting of multiple source files, set
	this variable to the path of the main source file on which LaTeX must
	be called.


------------------------------------------------------------------------------

						*latex-box-settings-windows*
Vim Windows ~

*g:LatexBox_split_width*	Default: 30

	Width of vertically split vim windows. Used for the table of contents.


==============================================================================

FREQUENTLY ASKED QUESTIONS			*latex-box-FAQ*

Q: How can I use SyncTeX with the Skim viewer?

A: Add the following line in your ~/.latexmkrc file: >
	$pdflatex = 'pdflatex -synctex=1 %O %S'
<  and create a "latex-search" mapping (<Leader>ls) in your ~/.vimrc: >
	map <silent> <Leader>ls :silent !/Applications/Skim.app/Contents/SharedSupport/displayline
		\ <C-R>=line('.')<CR> "<C-R>=LatexBox_GetOutputFile()<CR>" "%:p" <CR>
<  (inspired from vim-latex).


Q: How can I use xelatex instead of pdflatex for some documents only?

A: Instead of putting the settings in your ~/.latexmkrc file, put them in your
   document's working directory, in a file named either latexmkrc or .latexmkrc: >
	$pdflatex = 'xelatex %O %S'
<

==============================================================================

TODO						*latex-box-todo*

- Automatically find the main TeX document.
- Improve TOC jumping and filter out weird characters. Deal with multiple
  sections with the same name.
- Fix bugs?

==============================================================================

vim:tw=78:ts=8:sw=8:ft=help:norl:noet:

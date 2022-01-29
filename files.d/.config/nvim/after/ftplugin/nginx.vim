if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

"setlocal nolisp
"setlocal autoindent
setlocal expandtab
setlocal shiftwidth=4
setlocal tabstop=4
setlocal softtabstop=4

setlocal indentexpr=NGINXIndent(v:lnum)
setlocal indentkeys+=<:>,0=},0=)

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! NGINXIndent(lnum) abort
  let prevlnum = prevnonblank(a:lnum-1)
  if prevlnum == 0
    " top of file
    return 0
  endif

  " grab the previous and current line, stripping comments.
  let prevl = substitute(getline(prevlnum), '#.*$', '', '')
  let thisl = substitute(getline(a:lnum), '#.*$', '', '')
  let previ = indent(prevlnum)

  let ind = previ

  if prevl =~ '{\s*$'
    " previous line opened a block
    let ind += shiftwidth()
  endif

  if thisl =~ '^\s*}'
    " this line closed a block
    let ind -= shiftwidth()
  endif

  return ind
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

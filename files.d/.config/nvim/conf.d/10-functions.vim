"*****************************************************************************
"" Functions
"*****************************************************************************
" Function for running a command and then returning your cursor to its
" original position
function! Preserve(command)
    " Preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Do the business:
    execute a:command
    " Clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

" Remove unwanted whitespace at the end of lines
nmap _$ :call Preserve("%s/\\s\\+$//e")<CR>

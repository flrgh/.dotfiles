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
nnoremap _$ :call Preserve("%s/\\s\\+$//e")<CR>

" Stops current LSP clients and reloads vim
if !exists('*ReloadVim')
    function! ReloadVim()
        lua vim.lsp.stop_client(vim.lsp.get_active_clients())
        source $MYVIMRC
        echo "reloaded"
    endfunction
end

nnoremap <leader>vr :call  ReloadVim()<CR>

" tag management w/ gutentags

Plug 'ludovicchabant/vim-gutentags'

" tags
let g:gutentags_exclude_filetypes = ['js', 'javascript', 'css', 'html', 'scss', 'txt', 'md']
let g:gutentags_cache_dir = "~/.cache/gutentags"
let g:gutentags_project_info = [
\    {'type': 'python', 'file': 'requirements.txt'},
\    {'type': 'lua',    'file': 'spec'},
\    {'type': 'php',    'file': 'composer.json'}
\]
let g:gutentags_ctags_exclude = ['*.js', '*.css', '*.scss', '*.md', '*.html', '*.json', '*.phar', '**/phpstan/*', 'phpstan', '**/vendor/bin/*']
let g:gutentags_modules = ['ctags', 'gtags_cscope']
let g:gutentags_add_default_project_roots = 1
let g:gutentags_add_ctrlp_root_markers = 1

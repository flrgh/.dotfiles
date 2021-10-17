local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.api.nvim_command 'packadd packer.nvim'
end

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- file browser
  use {
    'preservim/nerdtree',
    config = function()
      vim.cmd [[nnoremap <leader>ff :NERDTreeToggle<CR>]]
      vim.cmd [[let NERDTreeShowHidden=1]]
    end,
  }

  use 'airblade/vim-gitgutter'

  -- hilight trailing whitespace
  use 'bronson/vim-trailing-whitespace'

  -- load tags in side pane
  use {
    'majutsushi/tagbar',
    config = function()
      vim.cmd [[nmap <silent> <F4> :TagbarToggle<CR>]]
      vim.cmd [[let g:tagbar_autofocus = 1]]
    end,
  }

  -- highlight indentation levels
  use 'lukas-reineke/indent-blankline.nvim'

  -- useful for targetting surrounding quotes/parens/etc
  use 'tpope/vim-surround'

  -- running shfmt commands on the buffer
  use {
    'z0mbix/vim-shfmt',
    ft = { 'sh', 'bash' },
  }

  -- syntax for .bats files
  use {
    'aliou/bats.vim',
    ft = { 'bats' },
  }

  -- fantastic git integration
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'

  --" Color
  use 'tomasr/molokai'
  use 'morhetz/gruvbox'
  use {
    'challenger-deep-theme/vim',
    as = 'challenger-deep',
  }
  use 'mhinz/vim-janah'
  use 'mhartington/oceanic-next'
  use {
    'joshdick/onedark.vim',
    branch = 'main',
  }
  use 'tjdevries/colorbuddy.vim'
  use 'tjdevries/gruvbuddy.nvim'
  use {
    'sainnhe/sonokai',
    config = function()
      vim.cmd [[
        let no_buffers_menu=1
        let g:sonokai_style = 'maia'
        colorscheme sonokai
      ]]
    end,
  }
  use 'folke/tokyonight.nvim'

  -- Buffer management
  use 'moll/vim-bbye'

  -- support .editorconfig files
  use 'editorconfig/editorconfig-vim'

  -- auto hlsearch stuff
  use 'romainl/vim-cool'

  -- devicon assets
  use 'kyazdani42/nvim-web-devicons'

  -- Nerd Fonts helper
  use 'lambdalisue/nerdfont.vim'

  -- statusline for neovim
  use 'glepnir/galaxyline.nvim'

  -- tabline for neovim
  use 'romgrk/barbar.nvim'

  -- align!
  use {
    'junegunn/vim-easy-align',
    config = function()
      -- Start interactive EasyAlign in visual mode (e.g. vipga)
      vim.cmd [[xmap ga <Plug>(EasyAlign)]]
      -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
      vim.cmd [[nmap ga <Plug>(EasyAlign)]]
    end,
  }

  -- lang: jq
  use {
    'vito-c/jq.vim',
    ft = { 'jq' },
  }

  -- lang: terraform
  use {
    'hashivim/vim-terraform',
    ft = { 'tf', 'terraform' },
  }

  -- lang: PHP
  use {
    'StanAngeloff/php.vim',
    ft = { 'php' },
  }

  -- lang: lua
  use {
    'euclidianAce/BetterLua.vim',
    config = function()
      vim.cmd [[let g:lua_inspect_events = '']]
    end
  }
  use 'rafcamlet/nvim-luapad'
  -- lua manual in vimdoc
  use 'wsdjeg/luarefvim'

  -- lang: teal
  use 'teal-language/vim-teal'

  -- lang: markdown
  use {
    'godlygeek/tabular',
    ft = { 'md', 'markdown' },
  }
  use {
    'plasticboy/vim-markdown',
    ft = { 'md', 'markdown' },
    config = function()
      vim.cmd [[let g:vim_markdown_folding_disabled = 1]]
    end,
  }

  -- lang: go
  use {
    'fatih/vim-go',
    ft = { 'go' },
    tag = 'v1.25',
    run = ':GoUpdateBinaries',
    config = function()
      vim.cmd [[
        " run :GoBuild or :GoTestCompile based on the go file
        function! s:build_go_files()
          let l:file = expand('%')
          if l:file =~# '^\f\+_test\.go$'
            call go#test#Test(0, 1)
          elseif l:file =~# '^\f\+\.go$'
            call go#cmd#Build(0)
          endif
        endfunction

        let g:go_list_type = "quickfix"
        let g:go_fmt_command = "goimports"
        let g:go_fmt_fail_silently = 1

        let g:go_highlight_types = 1
        let g:go_highlight_fields = 1
        let g:go_highlight_functions = 1
        let g:go_highlight_methods = 1
        let g:go_highlight_operators = 1
        let g:go_highlight_build_constraints = 1
        let g:go_highlight_structs = 1
        let g:go_highlight_generate_tags = 1
        let g:go_highlight_space_tab_error = 0
        let g:go_highlight_array_whitespace_error = 0
        let g:go_highlight_trailing_whitespace_error = 0
        let g:go_highlight_extra_types = 1

        let g:go_metalinter_autosave = 0


        " Automatically show type info when cursor is on an identifier
        let g:go_auto_type_info = 1
      ]]
    end,
  }

  -- lang: python
  use {
    'davidhalter/jedi-vim',
    ft = { 'python' },
    config = function()
      vim.cmd [[
        augroup vimrc-python
          autocmd!
          autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
              \ formatoptions+=croq softtabstop=4
              \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
        augroup END

        " jedi-vim
        let g:jedi#popup_on_dot = 0
        let g:jedi#goto_assignments_command = "<leader>g"
        let g:jedi#goto_definitions_command = "<leader>d"
        let g:jedi#documentation_command = "K"
        let g:jedi#usages_command = "<leader>n"
        let g:jedi#rename_command = "<leader>r"
        let g:jedi#show_call_signatures = "0"
        let g:jedi#completions_command = "<C-Space>"
        let g:jedi#smart_auto_mappings = 0

        " Syntax highlight
        " Default highlight is better than polyglot
        let g:polyglot_disabled = ['python']
        let python_highlight_all = 1
      ]]
    end,
  }
  use {
    'raimon49/requirements.txt.vim',
    ft = { 'requirements' },
  }

  -- FZF
  use {
    'junegunn/fzf.vim',
    requires = 'junegunn/fzf',
    config = function()
      vim.cmd [[
        nnoremap <silent> <C-p> :GFiles<CR>
        nnoremap <silent> <leader>b :Buffers<CR>
        nnoremap <silent> <leader>rg :Rg<CR>

        " ripgrep
        if executable('rg')
          let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
          set grepprg=rg\ --vimgrep
          command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
        endif
      ]]
    end,
  }

  use {
    'nvim-lua/popup.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
    },
  }

  -- LSP stuff
  use 'neovim/nvim-lsp'
  use 'neovim/nvim-lspconfig'
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
  }
  use 'nvim-treesitter/nvim-treesitter-textobjects'
  use 'nvim-treesitter/playground'
  use 'nvim-lua/lsp-status.nvim'
  use {
    'hrsh7th/nvim-compe',
    config = function()
      vim.cmd [[
        " Use <Tab> and <S-Tab> to navigate through popup menu
        inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
        inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
        let g:completion_auto_change_source = 1
        let g:completion_matching_smart_case = 1
        let g:completion_trigger_keyword_length = 2

        " Set completeopt to have a better completion experience
        set completeopt=menuone,noselect

        " Avoid showing message extra message when using completion
        set shortmess+=c
      ]]
    end,
  }
  use 'glepnir/lspsaga.nvim'
  use 'onsails/lspkind-nvim'

  use {
    'mhartington/formatter.nvim',
    config = function()
      require('formatter').setup({
        filetype = {
          json = {
            function()
              return {
                exe = "jq",
                args = {"."},
                stdin = true,
              }
            end,
          },
        },
      })
    end,
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      local actions = require "telescope.actions"
      require('telescope').setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
          layout_strategy = "vertical",
          layout_config = {
            horizontal = {
              width = 0.99,
              height = 0.9,
              prompt_position = "bottom",
              preview_cutoff = 120,
            },

            vertical = {
              width = 0.9,
              height = 0.9,
              prompt_position = "bottom",
              preview_cutoff = 40,
            },

            center = {
              width = 0.9,
              height = 0.9,
              preview_cutoff = 40,
              prompt_position = "top",
            },

            cursor = {
              width = 0.9,
              height = 0.9,
              preview_cutoff = 40,
            },

            bottom_pane = {
              height = 25,
              prompt_position = "top",
            },
          },
        },
      })
    end,
  }

  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    requires = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('telescope').setup({
        extensions = {
          fzf = {
            fuzzy                   = true,         -- false will only do exact matching
            override_generic_sorter = false,        -- override the generic sorter
            override_file_sorter    = true,         -- override the file sorter
            case_mode               = "smart_case", -- or "ignore_case" or "respect_case"
                                                    -- the default case_mode is "smart_case"
          }
        }
      })

      -- To get fzf loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require('telescope').load_extension('fzf')
    end,
  }

  use {
    'nvim-telescope/telescope-symbols.nvim',
    requires = {
      'nvim-telescope/telescope.nvim',
    },
  }

  use {
    'folke/which-key.nvim',
    config = function()
      require("which-key").setup {}
    end,
  }

  use 'aserowy/tmux.nvim'
end)

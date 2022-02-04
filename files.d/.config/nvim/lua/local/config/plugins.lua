local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.api.nvim_command 'packadd packer.nvim'
end

---@type nvim.packer.config
local config = {
  display = {
    open_fn = require('packer.util').float,
  },
  profile = {
    enable = false,
    threshold = 1,
  },

  log = {
  },
}

local g = require "local.config.globals"
if g.debug then
  config.log.level = "debug"
end

---@type nvim.packer.plugin[]
local plugins = {
  'wbthomason/packer.nvim',

  -- file browser
  {
    'preservim/nerdtree',
    config = function()
      local km = require('local.keymap')
      km.nnoremap.leader.ff = { ':NERDTreeToggle', silent = true }
      vim.cmd [[let NERDTreeShowHidden=1]]
    end,
  },

  -- adds some common readline key bindings to insert and command mode
  'tpope/vim-rsi',

  'airblade/vim-gitgutter',

  -- hilight trailing whitespace
  'bronson/vim-trailing-whitespace',

  -- load tags in side pane
  {
    'majutsushi/tagbar',
    config = function()
      local km = require('local.keymap')
      km.nmap.fn.F4 = { ':TagbarToggle', silent = true }
      vim.cmd [[let g:tagbar_autofocus = 1]]
    end,
  },

  -- highlight indentation levels
  'lukas-reineke/indent-blankline.nvim',

  -- useful for targetting surrounding quotes/parens/etc
  'tpope/vim-surround',

  -- running shfmt commands on the buffer
  {
    'z0mbix/vim-shfmt',
    ft = { 'sh', 'bash' },
  },

  -- syntax for .bats files
  {
    'aliou/bats.vim',
    ft = { 'bats' },
  },

  -- fantastic git integration
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  --" Color
  'tomasr/molokai',
  'morhetz/gruvbox',
  {
    'challenger-deep-theme/vim',
    as = 'challenger-deep',
  },
  'mhinz/vim-janah',
  'mhartington/oceanic-next',
  {
    'joshdick/onedark.vim',
    branch = 'main',
    config = function()
      vim.cmd "colorscheme onedark"
    end,
  },
  'tjdevries/colorbuddy.vim',
  'tjdevries/gruvbuddy.nvim',
  {
    'sainnhe/sonokai',
    config = function()
      vim.cmd [[
        let no_buffers_menu=1
        let g:sonokai_style = 'maia'
        "colorscheme sonokai
      ]]
    end,
  },
  'folke/tokyonight.nvim',

  -- Buffer management
  'moll/vim-bbye',

  -- support .editorconfig files
  'editorconfig/editorconfig-vim',

  -- auto hlsearch stuff
  'romainl/vim-cool',

  -- devicon assets
  'kyazdani42/nvim-web-devicons',

  -- Nerd Fonts helper
  'lambdalisue/nerdfont.vim',

  -- tabline for neovim
  'romgrk/barbar.nvim',

  -- align!
  {
    'junegunn/vim-easy-align',
    config = function()
      local km = require('local.keymap')
      -- Start interactive EasyAlign in visual mode (e.g. vipga)
      km.xmap.ga = '<Plug>(EasyAlign)'
      -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
      km.nmap.ga = '<Plug>(EasyAlign)'
    end,
  },

  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  },

  -- lang: jq
  {
    'vito-c/jq.vim',
    ft = { 'jq' },
  },

  -- lang: terraform
  {
    'hashivim/vim-terraform',
    ft = { 'tf', 'terraform' },
  },

  -- lang: PHP
  {
    'StanAngeloff/php.vim',
    ft = { 'php' },
  },

  -- lang: lua
  {
    'euclidianAce/BetterLua.vim',
    config = function()
      vim.cmd [[let g:lua_inspect_events = '']]
    end
  },
  'rafcamlet/nvim-luapad',
  -- lua manual in vimdoc
  'wsdjeg/luarefvim',
  -- lua neovim support
  'folke/lua-dev.nvim',

  -- lang: teal
  'teal-language/vim-teal',

  -- lang: markdown
  {
    'godlygeek/tabular',
    ft = { 'md', 'markdown' },
  },
  {
    'plasticboy/vim-markdown',
    ft = { 'md', 'markdown' },
    config = function()
      vim.cmd [[
        " disable header folding
        let g:vim_markdown_folding_disabled = 1

        " disable the conceal feature
        let g:vim_markdown_conceal = 0
      ]]
    end,
  },

  {
    -- iamcco/markdown-preview.nvim was another good choice here, but
    -- it has more dependencies and is a little more of a chore to install
    'davidgranstrom/nvim-markdown-preview',
    config = function()
      vim.cmd [[let g:nvim_markdown_preview_theme = 'github']]
    end,
    run = {
      os.getenv('HOME') .. '/.local/libexec/install/tools/install-pandoc',
      'npm install -g live-server'
    },
    ft = { 'md', 'markdown' },
  },

  -- lang: go
  {
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
  },

  -- FZF
  {
    'junegunn/fzf.vim',
    requires = 'junegunn/fzf',
    config = function()
      local km = require('local.keymap')
      -- fuzzy-find git-files
      km.nnoremap.ctrl.p    = {':GFiles',  silent = true }
      -- fuzzy-find buffers
      km.nnoremap.leader.b  = {':Buffers', silent = true }
      -- fuzzy-find with ripgrep
      km.nnoremap.leader.rg = {':Rg',      silent = true }

      vim.cmd [[
        " ripgrep
        if executable('rg')
          let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
          set grepprg=rg\ --vimgrep
          command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
        endif
      ]]
    end,
  },

  {
    'nvim-lua/popup.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
    },
  },

  -- LSP stuff
  'neovim/nvim-lspconfig',
  {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
  },
  'nvim-treesitter/nvim-treesitter-textobjects',
  'nvim-treesitter/playground',
  'nvim-lua/lsp-status.nvim',
  {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-calc',
      'hrsh7th/cmp-emoji',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-path',

      'onsails/lspkind-nvim',

      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local km = require('local.keymap')
      -- Set completeopt to have a better completion experience
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      -- Don't show the dumb matching stuff.
      vim.opt.shortmess:append "c"

      local lspkind = require "lspkind"
      lspkind.init()

      local get_cwd
      do
        local g = require "local.config.globals"
        local ws = g.workspace or os.getenv("PWD")
        if ws then
          get_cwd = function() return ws end
        end
      end

      local cmp = require 'cmp'
      cmp.setup({
        mapping = {
          -- replace ctrl+n/ctrl+p with ctrl+j/ctrl+k
          [km.Ctrl.j] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          [km.Ctrl.k] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          [km.Ctrl.n] = cmp.config.disable,
          [km.Ctrl.p] = cmp.config.disable,

          -- explicitly invoke completion
          [km.Ctrl.Space] = cmp.mapping.complete(),

          [km.Ctrl.e] = cmp.mapping.close(),

          [km.Enter] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },

          [km.Tab] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
          [km.S_Tab] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        },

        ---@type cmp.SourceConfig
        sources = {
          { name = 'nvim_lua' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path',
            option = { get_cwd = get_cwd },
          },
          { name = 'calc' },
          { name = 'emoji' },
        },

        ---@type cmp.ExperimentalConfig
        experimental = {
          native_menu = false,
          ghost_text = true,
        },

        ---@type cmp.SnippetConfig
        snippet = {
          expand = function(opts)
            require('luasnip').lsp_expand(opts.body)
          end,
        },

        ---@type cmp.FormattingConfig
        formatting = {
          format = lspkind.cmp_format({
            with_text = true,
            menu = {
              buffer   = "[buf]",
              nvim_lsp = "[lsp]",
              nvim_lua = "[nvim]",
              path     = "[path]",
              luasnip  = "[snip]",
            },
          }),
        },

      })

    end,
  },

  'glepnir/lspsaga.nvim',

  {
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
  },

  {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      local km = require('local.keymap')
      local actions = require "telescope.actions"

      -- turn on line numbers for previewers
      --
      -- this is kind of buggy, but it's the best I can do for now
      vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

      require('telescope').setup({
        pickers = {
          colorscheme = {
            enable_preview = true,
          },
        },

        defaults = {
          mappings = {
            i = {
              [km.Ctrl.j] = actions.move_selection_next,
              [km.Ctrl.k] = actions.move_selection_previous,
            },
          },

          layout_strategy = "flex",

          layout_config = {
            horizontal = {
              width = 0.95,
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
  },

  {
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
  },

  {
    'nvim-telescope/telescope-symbols.nvim',
    requires = {
      'nvim-telescope/telescope.nvim',
    },
  },

  {
    'nvim-telescope/telescope-frecency.nvim',

    config = function()
      require("telescope").load_extension("frecency")
    end,
    requires = {
      'nvim-telescope/telescope.nvim',
      'tami5/sqlite.lua'
    },
    rocks = {'sqlite'},
  },

  {
    'folke/which-key.nvim',
    config = function()
      require("which-key").setup {}
    end,
  },

  'aserowy/tmux.nvim',

  -- direnv support and syntax hilighting
  'direnv/direnv.vim',

  -- roku / brightscript support
  {
    'entrez/roku.vim',
    ft = { 'brs' }
  },

  -- annotation generation
  {
    'danymat/neogen',
    config = function()
      local ng = require 'neogen'
      ng.setup {
        enabled = true
      }
    end,
  },

}

for i = 1, #plugins do
  local plugin = plugins[i]
  if type(plugin) == "string" then
    plugin = { plugin }
    plugins[i] = plugin
  end
end


require('packer').startup({ plugins, config })

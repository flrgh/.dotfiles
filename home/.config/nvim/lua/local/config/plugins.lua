local km = require "local.keymap"
local evt = require "local.event"
local g = require "local.config.globals"
local fs = require "local.fs"

local cmd = vim.cmd


local conf = {
  lockfile = fs.join(g.dotfiles.config_nvim, "plugins.lock.json"),
  colorscheme = { "tokyonight", "catppuccin", "kanagawa" },
}

---@param plugin string|table
---@return table
local function hydrate(plugin)
  if type(plugin) == "string" then
    plugin = { plugin }
  end
  return plugin
end

-- for some reason, an empty string tells lazy.nvim to use the latest "stable"
-- version of a plugin
-- local LATEST_STABLE = ""


---@type table<string, LazySpec[]>
local plugins_by_filetype = {
  lua = {
    {
      'danymat/neogen',
      config = function()
        require("neogen").setup {
          enabled = true
        }
      end,
    },

    {
      "euclidianAce/BetterLua.vim",
      init = function()
        vim.g.lua_inspect_events = ""
      end,
    },

    -- lua manual in vimdoc
    "wsdjeg/luarefvim",

    -- lua neovim support
    "folke/neodev.nvim",
  },

  teal = {
    'teal-language/vim-teal',
  },

  -- lang: markdown
  markdown = {
    'godlygeek/tabular',

    {
      'plasticboy/vim-markdown',
      init = function()
          -- disable header folding
          vim.g.vim_markdown_folding_disabled = 1

          -- disable the conceal feature
          vim.g.vim_markdown_conceal = 0
      end,
    },

    {
      -- iamcco/markdown-preview.nvim was another good choice here, but
      -- it has more dependencies and is a little more of a chore to install
      'davidgranstrom/nvim-markdown-preview',
      init = function()
        vim.g.nvim_markdown_preview_theme = 'github'
      end,
      build = function()
        assert(os.execute(os.getenv('HOME') .. '/.local/libexec/install/tools/install-pandoc'))
        assert(os.execute('npm install -g live-server'))
      end,
    },
  },

  go = {
    {
      'fatih/vim-go',
      tag = 'v1.25',
      build = ':GoUpdateBinaries',
      config = function()
        local g = vim.g
        g.go_list_type = "quickfix"
        g.go_fmt_command = "goimports"
        g.go_fmt_fail_silently = 1

        g.go_highlight_types = 1
        g.go_highlight_fields = 1
        g.go_highlight_functions = 1
        g.go_highlight_methods = 1
        g.go_highlight_operators = 1
        g.go_highlight_build_constraints = 1
        g.go_highlight_structs = 1
        g.go_highlight_generate_tags = 1
        g.go_highlight_space_tab_error = 0
        g.go_highlight_array_whitespace_error = 0
        g.go_highlight_trailing_whitespace_error = 0
        g.go_highlight_extra_types = 1

        g.go_metalinter_autosave = 0

        -- Automatically show type info when cursor is on an identifier
        g.go_auto_type_info = 1

        cmd [[
          " run :GoBuild or :GoTestCompile based on the go file
          function! s:build_go_files()
            let l:file = expand('%')
            if l:file =~# '^\f\+_test\.go$'
              call go#test#Test(0, 1)
            elseif l:file =~# '^\f\+\.go$'
              call go#cmd#Build(0)
            endif
          endfunction
        ]]
      end,
    },
  },

  terraform = {
    'hashivim/vim-terraform',
  },

  php = {
    'StanAngeloff/php.vim',
  },

  bats = {
    -- syntax for .bats files
    'aliou/bats.vim',
  },

  sh = {
    -- running shfmt commands on the buffer
    'z0mbix/vim-shfmt',
  },

  -- roku / brightscript support
  brs = {
    'entrez/roku.vim',
  },

  nu = {
    {
      'LhKipp/nvim-nu',
      build = function()
        cmd 'TSInstall nu'
      end,
      config = function()
        require("nu").setup {
          -- LSP features require null-ls, but it is no more
          use_lsp_features = false,
          all_cmd_names = [[nu -c 'help commands | get name | str join "\n"']],
        }
      end,
    }
  },
}

---@type table<string, LazySpec[]>
local plugins_by_category = {
  appearance = {
    -- Color

    -- tokyonight-moon
    { "folke/tokyonight.nvim",
      enabled = true,
      priority = 2^16,
      lazy = false,
      config = function()
        require("tokyonight").setup()
      end,
    },

    -- catppuccin-mocha
    { "catppuccin/nvim", name = "catppuccin" },

    -- warm, low contrast
    -- kanagawa-dragon is pretty nice
    { "rebelot/kanagawa.nvim",
      config = function()
        cmd.colorscheme("kanagawa")
      end,
    },

    -- more bright, high contrast
    { "bluz71/vim-nightfly-colors",
      as = "nightfly",
      config = function()
        local g = vim.g
        g.nightflyCursorColor         = true
        g.nightflyItalics             = true
        g.nightflyTerminalColors      = false
        g.nightflyNormalFloat         = false
        g.nightflyUndercurls          = false
        g.nightflyVirtualTextColor    = true
        g.nightflyTransparent         = false
        g.nightflyUnderlineMatchParen = true

        --[[
          0 will display no window separators
          1 will display block separators; this is the default
          2 will diplay line separators
        ]]--
        g.nightflyWinSeparator        = 0

        --cmd.colorscheme("nightfly")
      end,
    },

    "lunarvim/darkplus.nvim",

    -- devicon assets
    "nvim-tree/nvim-web-devicons",

    -- Nerd Fonts helper
    'lambdalisue/nerdfont.vim',

    -- tabline for neovim
    {
      'romgrk/barbar.nvim',
      setup = function()
        require("barbar").setup({
          icons = {
            separator = {
              left = '▎',
            },
            inactive = {
              separator = {
                left =  '▎',
              },
            },
            pinned = {
              button = '車',
            },
            button = '',
            modified = {
              button= '●',
            },

          },
          animation = false,
          auto_hide = false,
          closable = true,
          clickable = true,
          maximum_padding = 4,
          maximum_length = 30,
          semantic_letters = true,
          no_name_title = nil,
        })
      end,
    },

    {
      "nvim-lualine/lualine.nvim",
      event = evt.VeryLazy,
      config = function()
        require("local.config.plugins.lualine").setup()
      end,
    },

    {
      -- TODO: is this still needed?
      'nvim-lua/popup.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
      },
    },

  },



  ui = {
    -- load tags in side pane
    {
      'majutsushi/tagbar',
      -- methodology:
      -- 1. init() creates a keyboard shortcut (<F4>) for TagbarToggle
      -- 2. lazy.nvim doesn't load the plugin until TagbarToggle is invoked
      lazy = true,
      init = function()
        km.nmap.fn.F4 = { ':TagbarToggle', silent = true }
        vim.g.tagbar_autofocus = 1
      end,
      cmd = { "TagbarToggle" },
    },

    -- better vim.ui
    {
      "stevearc/dressing.nvim",
      init = function()
        local select = vim.ui.select
        local input = vim.ui.input

        vim.ui.select = function(...)
          require("lazy").load({ plugins = { "dressing.nvim" } })
          vim.ui.select = select
          return select(...)
        end

        vim.ui.input = function(...)
          require("lazy").load({ plugins = { "dressing.nvim" } })
          vim.ui.input = input
          return input(...)
        end
      end,
    },
  },

  functions = {
    -- Buffer management
    {
      'moll/vim-bbye',
      event = evt.VimEnter,
    },

    -- FZF
    {
      'junegunn/fzf.vim',
      dependencies = {
        'junegunn/fzf',
      },
      init = function()
        -- fuzzy-find git-files
        km.nnoremap.ctrl.p    = {':GFiles',  silent = true }
        -- fuzzy-find buffers
        km.nnoremap.leader.b  = {':Buffers', silent = true }
        -- fuzzy-find with ripgrep
        km.nnoremap.leader.rg = {':Rg',      silent = true }

        vim.g.fzf_preview_window = {
          "right,50%,<70(down,70%)",
          "ctrl-/"
        }

        vim.g.fzf_layout = {
          window = {
            width = 0.9,
            height = 0.8
          }
        }
      end,
      cmd = { "GFiles", "Buffers", "Rg" },
    },
  },


  treesitter = {
    {
      'nvim-treesitter/nvim-treesitter',
      event = evt.VeryLazy,
      build = function()
        require('local.config.treesitter').bootstrap()
        cmd 'TSUpdateSync'
      end,
      config = function()
        require('local.config.treesitter').setup()
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      event = evt.VeryLazy,
      dependencies = { "nvim-treesitter" },
    },
    {
      'nvim-treesitter/playground',
      cmd = { "TSPlaygroundToggle" },
      dependencies = { "nvim-treesitter" },
    },
  },

  telescope = {
    {
      'nvim-telescope/telescope.nvim',
      event = evt.VeryLazy,
      dependencies = { 'nvim-lua/plenary.nvim' },
      branch = "0.1.x",
      config = function()
        require("local.config.plugins.telescope").setup()
      end,
    },

    {
      'nvim-telescope/telescope-fzf-native.nvim',
      event = evt.VeryLazy,
      build = 'make',
      dependencies = {
        'nvim-telescope/telescope.nvim',
      },
      config = function()
        require("local.config.plugins.telescope").setup_fzf_native()
      end,
    },

    {
      'nvim-telescope/telescope-symbols.nvim',
      event = evt.VeryLazy,
      dependencies = {
        'nvim-telescope/telescope.nvim',
      },
    },
  },

  -- git[hub] integration
  git = {
    {
      'tpope/vim-fugitive',
      event = evt.VeryLazy,
      dependencies = {
        'tpope/vim-rhubarb',
      },
    },

    'rhysd/conflict-marker.vim',

    {
      'lewis6991/gitsigns.nvim',
      event = evt.BufReadPre,
      config = function()
        require("gitsigns").setup({
          signcolumn = true,
          numhl      = false,
          word_diff  = false,

          max_file_length = 20000,

          current_line_blame = true,
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol',
            delay = 500,
          },

          yadm = {
            enable = false,
          }
        })
      end,
    },
  },


  editing = {
    -- auto hlsearch stuff
    {
      'romainl/vim-cool',
      event = evt.VeryLazy,
    },

    -- adds some common readline key bindings to insert and command mode
    {
      'tpope/vim-rsi',
      event = evt.VimEnter,
    },

    -- auto-insert function/block delimiters
    {
      'tpope/vim-endwise',
      event = evt.InsertEnter,
    },

    -- hilight trailing whitespace
    {
      'ntpeters/vim-better-whitespace',
      init = function()
        vim.g.better_whitespace_enabled = 1
        vim.g.strip_whitespace_on_save = 0
      end,
    },

    -- highlight indentation levels
    {
      "lukas-reineke/indent-blankline.nvim",
      event = evt.BufReadPre,
      main = "ibl",
      opts = {
        indent = {
          char = '┊',
          tab_char = '┋',
        },
        exclude = {
          filetypes = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy" },
          buftypes = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy" },
        },
        --show_trailing_blankline_indent = false,
        --show_current_context = false,
        scope = {
          enabled = false,
        },
      },
    },

    -- useful for targetting surrounding quotes/parens/etc
    {
      "kylechui/nvim-surround",
      event = evt.VimEnter,
      config = function()
        require("nvim-surround").setup()
      end,
    },

    -- align!
    {
      'junegunn/vim-easy-align',
      event = evt.VimEnter,
      config = function()
        -- Start interactive EasyAlign in visual mode (e.g. vipga)
        km.xmap.ga = '<Plug>(EasyAlign)'
        -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
        km.nmap.ga = '<Plug>(EasyAlign)'
      end,
    },

    {
      'numToStr/Comment.nvim',
      event = evt.VeryLazy,
      config = function()
        require('Comment').setup()
      end
    },

    {
      'L3MON4D3/LuaSnip',
      lazy = true,
      config = function()
        require("local.config.plugins.luasnip").setup()
      end,
      dependencies = {
        {
          "rafamadriz/friendly-snippets",
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end,
        },
      },
    },

    {
      'hrsh7th/nvim-cmp',
      event = evt.InsertEnter,
      dependencies = {
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-calc',
        'hrsh7th/cmp-emoji',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'ray-x/cmp-treesitter',
        'hrsh7th/cmp-nvim-lsp-signature-help',

        'onsails/lspkind-nvim',

        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
      },
      config = function()
        require("local.config.plugins.cmp").setup()
      end,
    },

    {
      'mhartington/formatter.nvim',
      ft = { "json" },
      config = function()
        require('formatter').setup({
          filetype = {
            json = {
              function()
                return {
                  exe = "jq",
                  args = {"-S", "."},
                  stdin = true,
                }
              end,
            },
          },
        })
      end,
    },
  },

  lsp = {
    -- LSP stuff
    {
      'neovim/nvim-lspconfig',
      event = evt.BufReadPre,
      dependencies = { "folke/neodev.nvim" },
      config = function()
        require('local.config.lsp')
        cmd 'LspStart'
      end,
    },

    {
      "nvimdev/lspsaga.nvim",
      event = evt.VeryLazy,
      branch = "main",
      config = function()
        require("lspsaga").setup({
          symbol_in_winbar = {
            enable = true, -- I only work on nvim 0.8
          },
          lightbulb = {
            -- this causes some visual defects, so it's disabled
            --
            -- the sign is also displayed in the gutter, so the virtual
            -- text is redundant anyways
            virtual_text = false,
          },

          code_action = {
            extend_gitsigns = true,
          },
        })
      end,
    },

    {
      "lewis6991/hover.nvim",
      event = evt.VeryLazy,
      config = function()
        require("hover").setup({
          init = function()
            require("hover.providers.lsp")
            require("hover.providers.man")
            require("hover.providers.gh")
          end,
          preview_opts = {
            border = nil,
          },
          title = true,
        })
      end,
    },

    {
      "zbirenbaum/copilot.lua",
      event = evt.VimEnter,
      enabled = false,
      config = function()
        require("copilot").setup({
          suggestion = { enabled = false },
          panel = { enabled = false },
        })
      end,
    },

    {
      "zbirenbaum/copilot-cmp",
      event = evt.VimEnter,
      enabled = false,
      dependencies = { "zbirenbaum/copilot.lua" },
      config = function ()
        require("copilot_cmp").setup()
      end
    },
  },

  plumbing = {
    "folke/lazy.nvim",

    -- filetype detection optimization
    "nathom/filetype.nvim",

    -- startup time profiling
    {
      "dstein64/vim-startuptime",
      cmd = "StartupTime",
    },
  },

  filetype = {
    -- support .editorconfig files
    'gpanders/editorconfig.nvim',

    -- direnv support and syntax hilighting
    'direnv/direnv.vim',

    -- etlua template syntax support
    {
      'VaiN474/vim-etlua',
      init = function()
        cmd [[au BufRead,BufNewFile *.etlua set filetype=etlua]]
      end,
    },

    -- detect jq scripts
    'vito-c/jq.vim',
  },

  -- FIXME: categorize these
  ["*"] = {
    {
      'folke/which-key.nvim',
      event = evt.VimEnter,
      config = function()
        vim.o.timeout = true
        vim.o.ttimeoutlen = 100
        require("which-key").setup({})
      end,
    },

    'aserowy/tmux.nvim',
  },

}

---@type LazySpec[]
local plugins = {}

do
  for ft, list in pairs(plugins_by_filetype) do
    for _, plugin in ipairs(list) do
      plugin = hydrate(plugin)

      plugin.ft = ft
      table.insert(plugins, plugin)
    end
  end
end

do
  for _, list in pairs(plugins_by_category) do
    for _, plugin in ipairs(list) do
      plugin = hydrate(plugin)
      table.insert(plugins, plugin)
    end
  end
end


do
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
   vim.fn.system({
     "git",
     "clone",
     "--filter=blob:none",
     "--single-branch",
     "https://github.com/folke/lazy.nvim.git",
     lazypath,
   })
  end
  vim.opt.runtimepath:prepend(lazypath)
end

require("lazy").setup(plugins, conf)

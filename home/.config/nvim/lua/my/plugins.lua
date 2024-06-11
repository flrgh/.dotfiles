local km = require "my.keymap"
local evt = require "my.event"
local g = require "my.config.globals"
local fs = require "my.utils.fs"

local Leader = km.Leader
local Ctrl = km.Ctrl

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

---@param name string
---@return function
local function file_config(name)
  return function()
    require("my.plugins." .. name)
  end
end


---@type table<string, LazySpec[]>
local plugins_by_filetype = {
  lua = {
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
      enabled = false,
      priority = 2^16,
      lazy = false,
      config = function()
        require("tokyonight").setup()
      end,
    },

    -- catppuccin-mocha
    { "catppuccin/nvim",
      enabled = false,
      name = "catppuccin",
      config = function()
        cmd.colorscheme("catppuccin-mocha")
      end,
    },

    { "marko-cerovac/material.nvim",
      config = function()
        --[[
          "darker"
          "lighter"
          "oceanic"
          "palenight"
          "deep ocean"
        ]]--
        vim.g.material_style = "oceanic"

        require('material').setup({
          plugins = {
            "gitsigns",
            "indent-blankline",
            "lspsaga",
            "nvim-cmp",
            "nvim-web-devicons",
            "telescope",
            "which-key",
            "nvim-notify",
          },
        })
        cmd.colorscheme("material")
      end,
    },

    -- warm, low contrast
    -- kanagawa-dragon is pretty nice
    { "rebelot/kanagawa.nvim",
      enabled = false,
      config = function()
        cmd.colorscheme("kanagawa")
      end,
    },

    -- more bright, high contrast
    { "bluz71/vim-nightfly-colors",
      as = "nightfly",
      enabled = false,
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

    { "lunarvim/darkplus.nvim",
      enabled = false,
    },

    -- devicon assets
    "nvim-tree/nvim-web-devicons",

    -- Nerd Fonts helper
    'lambdalisue/nerdfont.vim',

    -- tabline for neovim
    {
      'romgrk/barbar.nvim',
      dependencies = {
        "nvim-tree/nvim-web-devicons",
        "lewis6991/gitsigns.nvim",
      },
      config = file_config("barbar"),
    },

    {
      "nvim-lualine/lualine.nvim",
      event = evt.VeryLazy,
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = file_config("lualine"),
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
        km.nmap[km.F4] = { ':TagbarToggle', "Toggle Tag Bar", silent = true }
        vim.g.tagbar_autofocus = 1
      end,
      cmd = { "TagbarToggle" },
    },

    {
      "folke/noice.nvim",
      event = evt.VeryLazy,
      --enabled = function() return false end,
      dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
      },
      config = file_config("noice"),
    },

    { "rcarriga/nvim-notify",
      init = function()
        local notify = require "notify"
        notify.setup({
          timeout = 750,
          stages = "static",
        })

        vim.notify = notify
      end,
    },

    -- better vim.ui
    {
      "stevearc/dressing.nvim",
      enabled = true,
      config = function()
        require("dressing").setup({
          enabled = true,
        })
      end,
    },
  },

  functions = {
    -- Buffer management
    {
      'moll/vim-bbye',
      event = evt.VimEnter,
    },
  },

  treesitter = {
    {
      'nvim-treesitter/nvim-treesitter',
      event = evt.VeryLazy,
      build = function()
        require('my.config.treesitter').bootstrap()
        cmd 'TSUpdateSync'
      end,
      config = function()
        require('my.config.treesitter').setup()
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
      config = file_config("telescope"),
      keys = { Ctrl.p },
    },

    {
      'nvim-telescope/telescope-fzf-native.nvim',
      event = evt.VeryLazy,
      build = 'make',
      dependencies = {
        'nvim-telescope/telescope.nvim',
      },
      config = file_config("telescope-fzf-native"),
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
    { "justinmk/vim-ipmotion",
      config = function()
        -- prevent `{` and `}` navigation commands from opening folds
        vim.g.ip_skipfold = true
      end,
    },

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
        -- perform alignment in comments and strings
        vim.g.easy_align_ignore_groups = '[]'

        -- Start interactive EasyAlign in visual mode (e.g. vipga)
        km.xmap.ga = { '<Plug>(EasyAlign)', 'Easy Align' }
        -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
        km.nmap.ga = { '<Plug>(EasyAlign)', 'Easy Align' }
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
        require("my.plugins.luasnip").setup()
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
      config = file_config("cmp"),
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
      dependencies = { "folke/neodev.nvim" },
      config = function()
        require('my.config.lsp')
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

    {
      "robitx/gp.nvim",
      enabled = function()
        local home = os.getenv("HOME") or ""
        return fs.file_exists(home .. "/.config/openai/apikey.txt")
      end,
      config = function()
        require("gp").setup({
          openai_api_key = {
            "cat",
            os.getenv("HOME") .. "/.config/openai/apikey.txt",
          }
        })
      end,
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

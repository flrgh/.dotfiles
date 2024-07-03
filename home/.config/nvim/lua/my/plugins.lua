local km = require "my.keymap"
local evt = require "my.event"
local g = require "my.config.globals"
local fs = require "my.utils.fs"

local Ctrl = km.Ctrl
local Leader = km.Leader

local cmd = vim.cmd


-- https://lazy.folke.io/configuration
---@type LazyConfig
local conf = {
  lockfile = fs.join(g.dotfiles.config_nvim, "plugins.lock.json"),
  root = g.nvim.plugins,

  defaults = {
  },

  pkg = {
    -- we'll see...
    enabled = false,
  },

  install = {
    -- install missing plugins on startup
    missing = true,
  },

  change_detection = {
    enabled = false,
  },

  performance = {
    cache = {
      enabled = true,
    },

    reset_packpath = true,

    rtp = {
      reset = true,
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "rplugin",
        "spellfile",
        "tarPlugin",
        "tutor",
        "zipPlugin",
      },
    },
  },

  profiling = {
    loader  = g.debug,
    require = g.debug,
  },
}

do
  local lazypath = conf.root .. "/lazy.nvim"
  if not fs.exists(lazypath) then
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

---@param plugin string|table|LazySpec
---@return LazyPluginSpec
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
  },

  teal = {
    "teal-language/vim-teal",
  },

  -- lang: markdown
  markdown = {
    "godlygeek/tabular",

    {
      "plasticboy/vim-markdown",
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
      "davidgranstrom/nvim-markdown-preview",
      init = function()
        vim.g.nvim_markdown_preview_theme = "github"
      end,
      build = function()
        local opts = { text = true }
        local pandoc = vim.system(
          { g.home .. "/.local/libexec/install/tools/install-pandoc" },
          opts
        )

        local server = vim.system(
          { "npm", "install", "-g", "live-server" },
          opts
        )

        local result = pandoc:wait()
        if result.code ~= 0 then
          error("failed installing pandoc:\n"
              .. "stdout: " .. (result.stdout or "") .. "\n"
              .. "stderr: " .. (result.stderr or ""))
        end

        result = server:wait()
        if result.code ~= 0 then
          error("failed installing live-server:\n"
              .. "stdout: " .. (result.stdout or "") .. "\n"
              .. "stderr: " .. (result.stderr or ""))
        end
      end,
    },
  },

  terraform = {
    "hashivim/vim-terraform",
  },

  php = {
    "StanAngeloff/php.vim",
  },

  bats = {
    -- syntax for .bats files
    "aliou/bats.vim",
  },

  sh = {
    -- running shfmt commands on the buffer
    "z0mbix/vim-shfmt",
  },

  -- roku / brightscript support
  brs = {
    "entrez/roku.vim",
  },

  nu = {
    {
      "LhKipp/nvim-nu",
      build = function()
        cmd "TSInstall nu"
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
      --cond = false,
      priority = 2^16,
      lazy = false,
      config = function()
        require("tokyonight").setup()
      end,
      dependencies = {
        "echasnovski/mini.hipatterns",
      },
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
      lazy = false,
      priority = 2^16,
      config = function()
        --[[
          "darker"
          "lighter"
          "oceanic"
          "palenight"
          "deep ocean"
        ]]--
        vim.g.material_style = "oceanic"

        require("material").setup({
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
    {
      "nvim-tree/nvim-web-devicons",
      lazy = true,
    },

    -- Nerd Fonts helper
    {
      "lambdalisue/nerdfont.vim",
      lazy = true,
    },

    -- tabline for neovim
    {
      "romgrk/barbar.nvim",
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
  },

  ui = {
    -- load tags in side pane
    {
      "majutsushi/tagbar",
      -- methodology:
      -- 1. init() creates a keyboard shortcut (<F4>) for TagbarToggle
      -- 2. lazy.nvim doesn't load the plugin until TagbarToggle is invoked
      lazy = true,
      init = function()
        km.nmap[km.F4] = { ":TagbarToggle", "Toggle Tag Bar", silent = true }
        vim.g.tagbar_autofocus = 1
      end,
      cmd = { "TagbarToggle" },
    },

    {
      "folke/noice.nvim",
      event = evt.VeryLazy,
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
      event = evt.VeryLazy,
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
      "moll/vim-bbye",
      event = evt.VimEnter,
    },
  },

  treesitter = {
    {
      "nvim-treesitter/nvim-treesitter",
      event = evt.VeryLazy,
      build = function()
        require("my.config.treesitter").bootstrap()
        cmd "TSUpdateSync"
      end,
      config = function()
        require("my.config.treesitter").setup()
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      event = evt.VeryLazy,
      dependencies = { "nvim-treesitter" },
    },
    {
      "nvim-treesitter/nvim-treesitter-context",
      lazy = true,
      cmd = { "TSContextEnable", "TSContextDisable", "TSContextToggle" },
    },
  },

  telescope = {
    {
      "nvim-telescope/telescope.nvim",
      event = evt.VeryLazy,
      dependencies = {
        "nvim-lua/plenary.nvim",
        {
          "nvim-telescope/telescope-fzf-native.nvim",
          build = "make",
        },
        "nvim-telescope/telescope-symbols.nvim",
      },
      branch = "0.1.x",
      config = file_config("telescope"),
      keys = {
        Ctrl.p,
        Leader.pf,
        Leader.rg,
        Leader.vf,
        Leader.b,
      },
    },
  },

  -- git[hub] integration
  git = {
    {
      "tpope/vim-fugitive",
      event = evt.VeryLazy,
      dependencies = {
        "tpope/vim-rhubarb",
      },
    },

    "rhysd/conflict-marker.vim",

    {
      "lewis6991/gitsigns.nvim",
      lazy = true,
      config = function()
        require("gitsigns").setup({
          signcolumn = true,
          numhl      = false,
          word_diff  = false,

          max_file_length = 20000,

          current_line_blame = true,
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 500,
          },
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
      "romainl/vim-cool",
      event = evt.VeryLazy,
    },

    -- adds some common readline key bindings to insert and command mode
    {
      "tpope/vim-rsi",
      event = evt.VimEnter,
    },

    -- auto-insert function/block delimiters
    {
      "tpope/vim-endwise",
      event = evt.InsertEnter,
    },

    -- hilight trailing whitespace
    {
      "ntpeters/vim-better-whitespace",
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
          char = "┊",
          tab_char = "┋",
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
      "junegunn/vim-easy-align",
      event = evt.VimEnter,
      config = function()
        -- perform alignment in comments and strings
        vim.g.easy_align_ignore_groups = "[]"

        -- Start interactive EasyAlign in visual mode (e.g. vipga)
        km.xmap.ga = { "<Plug>(EasyAlign)", "Easy Align" }
        -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
        km.nmap.ga = { "<Plug>(EasyAlign)", "Easy Align" }
      end,
    },

    {
      "numToStr/Comment.nvim",
      event = evt.VeryLazy,
      config = function()
        require("Comment").setup()
      end
    },

    {
      "L3MON4D3/LuaSnip",
      lazy = true,
      version = "v2.*",
      build = "make install_jsregexp",
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
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-calc",
        "hrsh7th/cmp-emoji",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "ray-x/cmp-treesitter",
        "hrsh7th/cmp-nvim-lsp-signature-help",

        "onsails/lspkind-nvim",

        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = file_config("cmp"),
    },

    {
      "mhartington/formatter.nvim",
      ft = { "json" },
      config = function()
        require("formatter").setup({
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
      "neovim/nvim-lspconfig",
      event = evt.VeryLazy,
      dependencies = {
        "b0o/schemastore.nvim",
        "folke/neodev.nvim"
      },
      config = function()
        require("my.config.lsp")
        cmd "LspStart"
      end,
    },

    {
      "nvimdev/lspsaga.nvim",
      event = evt.VeryLazy,
      branch = "main",
      config = function()
        require("lspsaga").setup({
          -- display scope breadcrumbs in the winbar
          symbol_in_winbar = {
            enable = true,
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
            require("hover.providers.dictionary")
          end,
          preview_opts = {
            border = nil,
          },
          title = true,
          mouse_providers = {
            "LSP",
          },
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

    -- startup time profiling
    {
      "dstein64/vim-startuptime",
      cmd = "StartupTime",
      init = function()
        vim.g.startuptime_tries = 10
      end,
    },
  },

  filetype = {
    -- support .editorconfig files
    "gpanders/editorconfig.nvim",

    -- direnv support and syntax hilighting
    "direnv/direnv.vim",

    -- etlua template syntax support
    {
      "VaiN474/vim-etlua",
      init = function()
        cmd [[au BufRead,BufNewFile *.etlua set filetype=etlua]]
      end,
    },

    -- detect jq scripts
    "vito-c/jq.vim",

    "Glench/Vim-Jinja2-Syntax",
  },

  -- FIXME: categorize these
  ["*"] = {
    {
      "folke/which-key.nvim",
      event = evt.VimEnter,
      config = function()
        vim.o.timeout = true
        vim.o.ttimeoutlen = 100
        require("which-key").setup({})
      end,
    },

    "aserowy/tmux.nvim",
  },

}

---@type LazyPluginSpec[]
local plugins = {}
local idx = 0

do
  for ft, list in pairs(plugins_by_filetype) do
    for _, plugin in ipairs(list) do
      plugin = hydrate(plugin)

      plugin.ft = ft
      idx = idx + 1
      plugins[idx] = plugin
    end
  end
end

do
  for _, list in pairs(plugins_by_category) do
    for _, plugin in ipairs(list) do
      plugin = hydrate(plugin)
      idx = idx + 1
      plugins[idx] = plugin
    end
  end
end

require("lazy").setup(plugins, conf)

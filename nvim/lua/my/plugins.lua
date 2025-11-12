---@class my.plugins
local plugins = {}

---@type LazyPluginSpec[]
plugins.SPECS = {}
local SPECS = plugins.SPECS
local N = 0

---@class my.plugin.spec: LazyPluginSpec
---
---@field tags? string[]

---@alias my.plugin.def string|my.plugin.spec

---@alias my.plugin.tags table<string, any>

---@type table<string, my.plugin.tags>
plugins.TAGS = {}
local TAGS = plugins.TAGS


-- https://lazy.folke.io/configuration
---@type LazyConfig
plugins.CONF = require("my.lazy.config")
local CONF = plugins.CONF

---@alias my.plugin.cond fun(self: LazyPluginSpec, tags: my.plugin.tags, env: my.env):boolean|nil

---@type my.plugin.cond
local function return_nil(...) return nil end

---@type my.plugin.cond
local function return_true(...) return true end

---@type my.plugin.cond
local COND = return_nil


local km = require("my.keymap")
local evt = require("my.event")
local env = require("my.env")
local fs = require("my.std.fs")

local Ctrl = km.Ctrl
local Leader = km.Leader

local cmd = vim.cmd
local type = type
local byte = string.byte
local sub = string.sub
local BANG = byte("!")


---@param t nil|string|string[]
---@return nil|string[]
local function items(t)
  if type(t) == "string" then
    t = { t }
  end
  return t
end

---@param tags string[]
---@return my.plugin.tags
local function tomap(tags)
  for i = 1, #tags do
    local tag = tostring(tags[i])
    local value = true

    if byte(tag, 1) == BANG then
      tag = sub(tag, 2)
      value = false
    end

    tags[tag] = value
    tags[i] = nil
  end
  return tags
end

---@param t string[]
---@param extra nil|string|string[]
---@return nil|string[]
local function extend(t, extra)
  if t == nil then
    return items(extra)

  elseif extra == nil then
    return items(t)
  end

  local new = {}
  local n = 0

  if type(t) == "string" then
    n = n + 1
    new[n] = t

  else
    for i = 1, #t do
      n = n + 1
      new[n] = t[i]
    end
  end

  if type(extra) == "string" then
    n = n + 1
    new[n] = extra

  else
    for i = 1, #extra do
      n = n + 1
      new[n] = extra[i]
    end
  end

  return new
end

---@param self LazyPluginSpec
---@return boolean
local function plugin_cond(self)
  local name = self.name or self[1]
  assert(type(name) == "string")

  local tags = assert(TAGS[name], "no plugin tags for " .. name)

  local default_cond = COND(self, tags, env)

  -- enabled if COND() returns true or nil
  local default_enabled = default_cond == true or default_cond == nil

  -- enabled only if COND() returns true
  local default_disabled = default_cond == true

  if tags.required then
    return default_enabled

  elseif env.editor then
    return default_enabled

  elseif env.pager and (
      tags.pager
      or tags.plumbing
      or tags.ui
      or tags.colorscheme
      or tags.man
      or tags["*"]
    )
  then
    return default_enabled
  end

  return default_disabled
end

---@param cond fun(self: LazyPluginSpec):boolean
---@return fun(self: LazyPluginSpec):boolean
local function wrap_plugin_cond(cond)
  ---@param self LazyPluginSpec
  ---@return boolean
  return function(self)
    local res = cond(self)
    if res == nil or res == true then
      res = plugin_cond(self)
    end
    return res
  end
end


---@param plugin my.plugin.def
---@param lang? string
---@param category? string
---@return LazyPluginSpec
local function hydrate(plugin, lang, category)
  local name = plugin

  if type(plugin) == "table" then
    -- no further processing (it's not gonna run anyways)
    if plugin.enabled == false or plugin.cond == false then
      plugin.tags = nil
      return plugin
    end

    name = plugin.name or plugin[1]

  else
    plugin = { plugin }
  end

  assert(type(name) == "string")
  name = name:gsub("^[^/]+/", "")
  plugin.name = name

  plugin.ft = extend(plugin.ft, lang)

  local tags = extend({}, plugin.tags)
  plugin.tags = nil

  tags = extend(tags, plugin.ft)
  tags = extend(tags, category)

  TAGS[name] = tomap(tags)

  if plugin.cond == nil or plugin.cond == true then
    plugin.cond = plugin_cond
  else
    assert(type(plugin.cond) == "function")
    plugin.cond = wrap_plugin_cond(plugin.cond)
  end

  return plugin
end

-- for some reason, an empty string tells lazy.nvim to use the latest "stable"
-- version of a plugin
-- local LATEST_STABLE = ""

---@param name string
---@return function
local function file_config(name)
  local modname = "my.plugins." .. name
  return function()
    require(modname)
  end
end

do
  ---@type table<string, my.plugin.def[]>
  local plugins_by_language = {
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
          local _cmd = require("my.std.cmd")

          local pandoc = _cmd.new("ineed")
            :args({ "install", "pandoc" })
            :run()

          local server = _cmd.new("npm")
            :args({ "install", "-g", "live-server" })
            :run()

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

  ---@type table<string, my.plugin.def[]>
  local plugins_by_category = {
    colorscheme = {
      -- tokyonight-moon
      { "folke/tokyonight.nvim",
        --cond = false,
        priority = 2^16,
        lazy = false,
        config = function()
          require("tokyonight").setup()
        end,
        dependencies = {
          "nvim-mini/mini.hipatterns",
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
    },

    ui = {
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
        init = function()
          vim.g.barbar_auto_setup = false
        end,
        config = file_config("barbar"),
      },

      {
        "nvim-lualine/lualine.nvim",
        event = evt.user.VeryLazy,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = file_config("lualine"),
      },

      -- load tags in side pane
      {
        "majutsushi/tagbar",
        -- methodology:
        -- 1. init() creates a keyboard shortcut (<F4>) for TagbarToggle
        -- 2. lazy.nvim doesn't load the plugin until TagbarToggle is invoked
        lazy = true,
        init = function()
          km.nmap(km.F4)
            :desc("Toggle Tag Bar")
            :cmd("TagbarToggle")
          vim.g.tagbar_autofocus = 1
        end,
        cmd = { "TagbarToggle" },
      },

      { "rcarriga/nvim-notify",
        event = evt.user.VeryLazy,
        tags = { "pager" },
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
        event = evt.user.VeryLazy,
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
        -- FIXME: figure out how to make this work with my lua module search autocommand
        -- event = evt.user.VeryLazy,
        build = function()
          require("my.treesitter").bootstrap()
          cmd "TSUpdateSync"
        end,
        config = function()
          require("my.treesitter").setup()
        end,
      },
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        event = evt.user.VeryLazy,
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
        event = evt.user.VeryLazy,
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
        event = evt.user.VeryLazy,
        dependencies = {
          "tpope/vim-rhubarb",
        },
        config = function()
          km.nnoremap(Leader.o)
            :desc("Open current line in github browser")
            :cmd(".GBrowse")

          km.nnoremap(Leader.g)
            :desc("fuGITive")
            :cmd("G")
        end,
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

    navigation = {
      { "justinmk/vim-ipmotion",
        config = function()
          -- prevent `{` and `}` navigation commands from opening folds
          vim.g.ip_skipfold = true
        end,
      },

      -- auto hlsearch stuff
      {
        "romainl/vim-cool",
        event = evt.user.VeryLazy,
      },
    },

    editing = {
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
          km.xmap("ga")
            :desc("Easy Align (v)")
            :plugin("EasyAlign")

          -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
          km.nmap("ga")
            :desc("Easy Align (n)")
            :plugin("EasyAlign")
        end,
      },

      {
        "numToStr/Comment.nvim",
        event = evt.user.VeryLazy,
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
        "saghen/blink.cmp",
        enabled = false,
        version = "v1.*",
        config = file_config("blink"),
        dependencies = {
          "moyiz/blink-emoji.nvim",
          "Kaiser-Yang/blink-cmp-git",
          "MahanRahmati/blink-nerdfont.nvim",
        },
      },

      {
        "hrsh7th/nvim-cmp",
        enabled = true,
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
          "hrsh7th/cmp-nvim-lsp-document-symbol",

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
        lazy = false, -- needs to be injected into rtp early on
      },

      {
        -- JSON schema supplier for jsonls and yamlls
        "b0o/schemastore.nvim",
        lazy = true,
      },

      {
        "nvimdev/lspsaga.nvim",
        event = evt.user.VeryLazy,
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
        cond = function()
          return fs.file_exists(env.home .. "/.config/openai/apikey.txt")
        end,
        config = function()
          require("gp").setup({
            openai_api_key = {
              "cat",
              env.home .. "/.config/openai/apikey.txt",
            }
          })
        end,
      },
    },

    plumbing = {
      { "folke/lazy.nvim", tags = { "required" } },

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

      -- turn off fancy features that are slow when opening a big file
      {
        "ouuan/nvim-bigfile",
        config = function()
          require("bigfile").setup {
            -- Default size limit in bytes
            size_limit = 1 * 1024 * 1024,

            -- Per-filetype size limits
            ft_size_limits = {
              -- javascript = 100 * 1024, -- 100KB for javascript files
            },

            -- Show notifications when big files are detected
            notification = true,

            -- Enable basic syntax highlighting (not TreeSitter) for big files
            -- (tips: it will be automatically disabled if too slow)
            syntax = false,

            -- Custom additional hook function to run when big files are detected
            -- hook = function(buf, ft)
            --   vim.b.minianimate_disable = true
            -- end,
            hook = nil,
            }
        end,
      },

      -- syntax detection for kitty.conf files
      "fladson/vim-kitty",
    },

    filesystem = {
      {
        "stevearc/oil.nvim",
        dependencies = {
          "nvim-tree/nvim-web-devicons",
        },
        config = file_config("oil"),
      }
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

      {
        "aserowy/tmux.nvim",
        cond = function()
          return os.getenv("TMUX") ~= nil
            or os.getenv("TMUX_PANE") ~= nil
            or os.getenv("TMUX_SOCKET") ~= nil
        end,
      },
    },

  }

  do
    for lang, list in pairs(plugins_by_language) do
      for _, plugin in ipairs(list) do
        N = N + 1
        SPECS[N] = hydrate(plugin, lang)
      end
    end
  end

  do
    for cat, list in pairs(plugins_by_category) do
      for _, plugin in ipairs(list) do
        N = N + 1
        SPECS[N] = hydrate(plugin, nil, cat)
      end
    end
  end
end

do
  ---@type Lazy
  local lazy

  local function _init()
    if lazy then
      return true
    end

    local ok, _lazy = pcall(require, "lazy")
    if ok then
      lazy = _lazy
      return true
    end

    return false
  end

  ---@type table<string, LazyPlugin>
  local by_name

  ---@type LazyPlugin[]
  local list

  ---@type string[]
  local lua_dirs

  local function _index()
    if list then return end

    if not _init() then
      return
    end

    by_name = {}
    list = {}
    lua_dirs = {}
    local n = 0

    ---@param name string
    ---@param p LazyPlugin
    local function add_name(name, p)
      local current = by_name[name]
      if current and current ~= p then
        error("name collision for plugins " .. p.name .. " and " .. current.name)
      end
      by_name[name] = p
    end

    ---@param name string
    ---@param p LazyPlugin
    local function add(name, p)
      assert(type(name) == "string")
      assert(type(p) == "table")

      add_name(name, p)
      add_name(name:lower(), p)

      if name:find("%.nvim$") then
        add(name:sub(1, -6), p)

      elseif name:find("%.vim$") then
        add(name:sub(1, -5), p)
      end
    end

    for _, p in ipairs(lazy.plugins()) do
      -- index by name
      add(p.name, p)

      if p.url then
        -- e.g. https://github.com/b0o/schemastore.nvim.git
        local user, name = p.url:match("github%.com/([^/]+)/(.+)(%.git)$")
        if user then
          -- index by {{ github.user }}/{{ github.repo }}
          add(user .. "/" .. name, p)
        end
      end

      n = n + 1
      list[n] = p
      lua_dirs[n] = p.dir .. "/lua"
    end
  end

  ---@param name string
  ---@return LazyPlugin? plugin
  ---@return string? error
  function plugins.get(name)
    if not _init() then
      return nil, "lazy.nvim is not loaded"
    end

    _index()

    local plugin = by_name[name] or by_name[name:lower()]
    if plugin then
      return plugin
    end

    return nil, "plugin not found"
  end

  ---@param name string
  ---@return boolean
  function plugins.installed(name)
    return plugins.get(name) ~= nil
  end

  ---@return LazyPlugin[]
  function plugins.list()
    if not _init() then
      return {}
    end

    _index()

    return list
  end


  ---@return string[]
  function plugins.lua_dirs()
    if not _init() then
      return {}
    end
    return lua_dirs
  end
end

local _loaded = false

---@param cond? my.plugin.cond
function plugins.load(cond)
  if _loaded then
    return
  end

  vim.go.loadplugins = true

  assert(cond == nil or type(cond) == "function")
  COND = cond or COND or return_nil

  require("my.settings")
  require("my.lazy.install")
  require("lazy").setup(SPECS, CONF)

  _loaded = true
end

function plugins.bootstrap()
  vim.go.loadplugins = true

  COND = return_true

  require("my.settings")
  require("my.lazy.install")
  local lazy = require("lazy")

  CONF.wait = true

  lazy.setup(SPECS, CONF)
  lazy.restore(CONF)
  lazy.build(CONF)
end


return plugins

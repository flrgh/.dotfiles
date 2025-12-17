---@class my.plugins
local plugins = {}

-- have we called lazy.setup() yet
plugins.LOADED = false

---@type LazyPluginSpec[]
plugins.SPECS = {}
local SPECS = plugins.SPECS
local N = 0

local PRIORITY_HIGH = 2^16


---@class my.plugin.spec: LazyPluginSpec
---
---@field tags? string[]
---@field files? my.plugin.files

---@alias my.plugin.def string|my.plugin.spec

---@alias my.plugin.tags table<string, any>

---@alias my.plugin.files table<string, table|string|function>

---@type table<string, my.plugin.tags>
plugins.TAGS = {}
local TAGS = plugins.TAGS

---@class my.plugin.meta
---
---@field tags my.plugin.tags
---@field files my.plugin.files

---@type table<string, my.plugin.meta>
plugins.META = {}
local META = plugins.META


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
  if type(plugin) == "string" then
    return hydrate({ plugin }, lang, category)
  end

  assert(type(plugin) == "table")

  -- no further processing (it's not gonna run anyways)
  if plugin.enabled == false or plugin.cond == false then
    plugin.tags = nil
    return plugin
  end

  local slug = assert(plugin[1])

  if not plugin.name then
    plugin.name = slug:gsub("^[^/]+/", "")
  end
  local name = plugin.name

  plugin.ft = extend(plugin.ft, lang)

  if category == "colorscheme" or category == "ui" then
    plugin.priority = plugin.priority or PRIORITY_HIGH
    if plugin.lazy == nil and plugin.event == nil then
      plugin.lazy = false
    end
  end

  local tags = extend({}, plugin.tags)
  plugin.tags = nil

  tags = extend(tags, plugin.ft)
  tags = extend(tags, category)

  local meta = {
    tags = tomap(tags),
    files = nil,
  }
  META[name] = meta
  TAGS[name] = meta.tags

  if plugin.files then
    meta.files = plugin.files
  end
  plugin.files = nil


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

    -- roku / brightscript support
    brs = {
      "entrez/roku.vim",
    },
  }

  ---@type table<string, my.plugin.def[]>
  local plugins_by_category = {
    colorscheme = {
      -- tokyonight-moon
      { "folke/tokyonight.nvim",
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
        files = {
          ["lua/lualine/themes/material.lua"] = "clobber",
        },
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
        branch = "master",

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
        branch = "master",
        event = evt.user.VeryLazy,
        dependencies = {
          {
            "nvim-treesitter/nvim-treesitter",
            branch = "master",
          }
        },
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
        tags = {
          "pager", -- include in manpager mode
        },
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
        files = {
          ["lsp/*.lua"] = function(fname, opts)
            local servers = require("my.lsp").SERVERS
            for i = 1, #servers do
              local exp = "lsp/" .. servers[i] .. ".lua"
              if exp == fname then
                return
              end
            end
            opts.skip = true
          end,
        },
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
      "tpope/vim-sleuth",

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

    require("my.settings")
    require("my.lazy.install")

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

function plugins.lockfile()
  return fs.load_json_file(CONF.lockfile)
end

---@param cond? my.plugin.cond
function plugins.load(cond)
  if plugins.LOADED then
    return
  end

  vim.go.loadplugins = true

  assert(cond == true or cond == nil or type(cond) == "function")
  if cond == true then
    cond = return_true
  end
  COND = cond or COND or return_nil

  require("my.settings")
  require("my.lazy.install")
  require("lazy").setup(SPECS, CONF)

  plugins.LOADED = true
end

function plugins.bootstrap()
  vim.go.loadplugins = true

  COND = return_true

  require("my.settings")
  require("my.lazy.install")
  local lazy = require("lazy")

  CONF.wait = true

  lazy.setup(SPECS, CONF)
  lazy.clean(CONF)
  lazy.restore(CONF)
  lazy.build(CONF)
end


function plugins.bundle()
  ---@class typopts
  ---
  ---@field namespace? boolean
  ---@field auto_namespace? boolean
  ---@field ft_namespace? boolean
  ---
  ---@field concat? boolean
  ---
  ---@field clobber? boolean
  ---@field skip? boolean
  ---@field plugin_matched? boolean

  ---@type table<string, typopts>
  local TYPES = {
    -- automatically loaded scripts
    autoload = {
    },
    -- color scheme files
    colors = {
    },
    -- compiler files
    compiler = {
    },
    -- documentation
    doc = {
    },
    -- filetype plugins
    ftplugin = {
      ft_namespace = true,
    },
    -- filetype detection plugins
    ftdetect = {
      concat = true,
    },
    -- indent scripts
    indent = {
    },
    -- key mapping files
    keymap = {
    },
    -- menu translations
    lang = {
    },
    -- LSP client configurations
    lsp = {
    },
    -- Lua
    lua = {
    },
    -- packages
    pack = {
    },
    -- treesitter syntax parsers
    parser = {
    },
    -- plugin scripts
    plugin = {
    },
    -- treesitter queries
    queries = {
      auto_namespace = true,
    },
    -- remote-plugin scripts
    rplugin = {
    },
    -- spell checking files
    spell = {
    },
    -- syntax files
    syntax = {
    },
    -- tutorial files
    tutor = {
    },

    after = {
    },
  }

  do
    local after = {}
    for k, v in pairs(TYPES) do
      after["after/" .. k] = v
    end

    for k, v in pairs(after) do
      TYPES[k] = v
    end
  end

  local FILES = {}
  local CLOBBERED = {}

  local bundle = env.nvim.bundle.root
  local dotfiles = env.dotfiles.root
  local lazy = env.nvim.plugins
  local std = require("my.std")
  local table = std.table
  local string = std.string

  local uv = vim.uv
  local scandir = uv.fs_scandir
  local scandir_next = uv.fs_scandir_next
  local link = uv.fs_link
  local is_dir = std.path.dir_exists
  local is_file = std.path.file_exists
  local stat = std.path.stat
  local mkdir = std.path.mkdir
  local fmt = string.format

  local newbundle = bundle .. "." .. tostring(uv.getpid())
  local B = {
    root = newbundle,
    main = newbundle .. "/main",
    namespaced = newbundle .. "/ns",
  }

  assert(mkdir(B.root))
  assert(mkdir(B.main))
  assert(mkdir(B.namespaced))

  local running = 0
  local failed = false

  local function done()
    running = running - 1
    assert(running >= 0)
  end

  ---@return boolean
  local function start()
    if not failed then
      running = running + 1
    end
    return not failed
  end

  local function fail(f, ...)
    done()
    failed = true
    vim.print(fmt(f, ...))
  end

  local function warn(f, ...)
    vim.print("WARN " .. fmt(f, ...))
  end

  ---@param plugin LazyPlugin
  ---@param fname string
  ---@param opts typopts
  ---@return typopts
  local function merge_plugin_opts(plugin, fname, opts)
    if opts.plugin_matched then
      return opts
    end

    local meta = META[plugin.name]
    local files = meta and meta.files
    if not files then
      return opts
    end

    for pat, fopts in pairs(files) do
      if string.globmatch(pat, fname) then
        local ty = type(fopts)
        opts = table.clone(opts)
        if ty == "table" then
          for k, v in pairs(fopts) do
            opts[k] = v
          end

        elseif ty == "string" then
          opts[fopts] = true

        else
          assert(ty == "function")
          fopts(fname, opts, plugin)
        end

        opts.plugin_matched = true
        return opts
      end
    end

    return opts
  end

  ---@param plugin LazyPlugin
  ---@param fname string
  ---@param opts typopts
  local function concat_file(plugin, fname, opts)
    if not start() then return end

    opts = merge_plugin_opts(plugin, fname, opts)
    if opts.skip then
      return done()
    end

    local ext = fname:sub(-4)
    local header, footer
    local src = plugin.dir .. "/" .. fname
    local basename

    if ext == ".vim" then
      header = [[" BEGIN ]] .. src
      footer = [[" END ]] .. src
      basename = "user_bundled"

    elseif ext == ".lua" then
      header = [[-- BEGIN ]] .. src
      footer = [[-- END ]] .. src
      basename = "user_bundled"

    elseif fname == "doc/tags" then
      header = ""
      footer = ""
      basename = "tags"
      ext = ""

    else
      return fail("unknown bundled file extension: %s", ext)
    end

    local src = plugin.dir .. "/" .. fname

    local dst = B.main .. "/" .. fname:gsub("[^/]+$", basename) .. ext
    local data, err = fs.read_file(src)
    if failed then return done() end
    if not data then
      return fail("failed reading %s for concat action: %s", src, err)
    end

    if failed then return done() end

    data = header .. "\n" .. data .. "\n" .. footer .. "\n\n"

    local ok
    ok, err = fs.append_file(dst, data)
    if not ok then
      return fail("failed appending %s to %s: %s",
                  src, dst, err)
    end

    return done()
  end

  ---@param plugin LazyPlugin
  ---@param fname string
  ---@param opts typopts
  local function on_file(plugin, fname, opts)
    if not start() then return end

    opts = merge_plugin_opts(plugin, fname, opts)
    if opts.skip then
      return done()
    end

    if fname == "doc/tags" then
      --concat_file(plugin, fname, opts)
      return done()
    end

    local dst
    if opts.namespace then
      dst = B.namespaced .. "/" .. plugin.name .. "/" .. fname

    elseif opts.ft_namespace then
      local dir, base, ext = assert(fname:match("^(.*)/([^/]+)(%.[a-z]+)$"))
      local slug = plugin.name:gsub("%.", "_")
      if dir ~= "" then
        dir = dir .. "/"
      end
      dst = B.main .. "/" .. dir .. base .. "/" .. slug .. ext

    elseif opts.concat then
      concat_file(plugin, fname, opts)
      return done()
    else
      dst = B.main .. "/" .. fname
    end

    if CLOBBERED[dst] then
      if opts.clobber then
        assert(CLOBBERED[dst] == plugin)
      else
        return done()
      end
    end

    if FILES[dst] and FILES[dst] ~= plugin then
      if opts.auto_namespace then
        assert(not opts.namespace)
        on_file(plugin, fname, { namespace = true })
        return done()
      end

      warn("CONFLICT! file: %s, plugins: %s, %s\n",
           fname, FILES[dst].name, plugin.name)
    end

    if opts.clobber then
      CLOBBERED[dst] = plugin
    end

    FILES[dst] = plugin

    local src = plugin.dir .. "/" .. fname

    local sstat, dstat, err
    sstat, err = stat(src)
    if failed then return done() end

    if not sstat then
      return fail("stat(%q) => %s\n", src, err)
    end

    dstat, err = stat(dst)
    if failed then return done() end

    if dstat then
      if dstat.ino == sstat.ino then
        return done()
      end

      if not opts.clobber then
        warn("CONFLICT: link(%q, %q) => exists (inode mismatch)\n", src, dst, err)
      end

      uv.fs_unlink(dst, function(err, ok)
        if not ok then
          return fail("unlink(%q) => %s\n", dst, err)
        end

        if failed then return done() end

        on_file(plugin, fname, opts)
      end)
    end

    if opts.namespace or opts.ft_namespace then
      local parent = dst:gsub("/+[^/]+$", "")
      local ok, err = std.path.mkdir_all(parent)
      if not ok then
        return fail("mkdir_all(%q) => %s\n", parent, err)
      end
    end

    link(src, dst, function(err, ok)
      if err or not ok then
        return fail("link(%q, %q) => %s\n", src, dst, err)
      end
      done()
    end)
  end

  ---@param plugin LazyPlugin
  ---@param dir string
  ---@param opts typopts
  local function on_dir(plugin, dir, opts)
    if not start() then return end

    opts = merge_plugin_opts(plugin, dir, opts)
    if opts.skip then
      return done()
    end

    local src = plugin.dir .. "/" .. dir

    local s = scandir(src)
    if not s then
      return done()
    end

    local made_dst = false

    while not failed do
      local child = scandir_next(s)
      if not child then
        return done()
      end

      if dir == "after" then
        -- NOTE: does not merge_opts(), is that okay?
        opts = TYPES[child] or opts
      end

      if not made_dst then
        local dst
        if opts.namespace then
          dst = B.namespaced .. "/" .. plugin.name .. "/" .. dir
        else
          dst = B.main .. "/" .. dir
        end
        local err
        made_dst, err = std.path.mkdir_all(dst)
        if not made_dst then
          return fail("Failed creating directory %s: %s\n", dst, err)
        end
      end

      local child_src = src .. "/" .. child
      if is_dir(child_src) then
        on_dir(plugin, dir .. "/" .. child, opts)

      elseif is_file(child_src) then
        on_file(plugin, dir .. "/" .. child, opts)
      end
    end

    return done()
  end

  ---@param name string
  local function copy_plugin(name)
    if not start() then return end

    local p = assert(plugins.get(name), "plugin not found: " .. name)
    p.name = p.name or p[1]

    local dir = lazy .. "/" .. name
    if not is_dir(dir) then
      return done()
    end

    local s = scandir(dir)
    if not s then
      return done()
    end

    while not failed do
      local child = scandir_next(s)
      if not child then
        return done()
      end

      local child_path = dir .. "/" .. child
      local ty = TYPES[child]
      if ty and is_dir(child_path) then
        on_dir(p, child, ty)
      end
    end

    return done()
  end

  do
    local dir = assert(scandir(lazy))
    while not failed do
      local child = scandir_next(dir)
      if not child then
        break
      end

      copy_plugin(child)
    end
  end

  vim.wait(5000, function()
    vim.print("RUNNING: " .. tostring(running))
    return running == 0
  end, 100)

  assert(running == 0, "not finished running")
  assert(not failed, "something failed")

  local ok, err = vim.uv.fs_rename(env.nvim.bundle.root, B.root .. ".old")
  assert(ok, "failed renaming bundle directory: " .. tostring(err))

  local manifest = {
    names = {},
    plugins = {},
  }

  local plugin_files = {}
  for fname, p in pairs(FILES) do
    local files = plugin_files[p.name]
    if not files then
      files = {}
      plugin_files[p.name] = files
    end

    table.insert(files, fname:sub(#B.root + 2))
  end


  for i, p in ipairs(plugins.list()) do
    manifest.plugins[i] = {
      index = i,

      name = p.name,
      dir = p.dir,
      url = p.url,

      lazy = p.lazy,
      event = p.event,
      keys = p.keys,
      cmd = p.cmd,

      has_init = p.init ~= nil,
      has_config = p.config ~= nil,
      has_opts = p.opts ~= nil,

      names = {},
      files = plugin_files[p.name],
      tags = TAGS[p.name],

      branch = p.branch,
      version = p.version,
      commit = p.commit,
      updated = nil,
    }

    if manifest.plugins[i].files then
      table.sort(manifest.plugins[i].files)
    end

    local names = manifest.plugins[i].names
    local name = p.name
    local function add_name(s)
      assert(manifest.names[s] == nil or manifest.names[s] == i)
      if not manifest.names[s] then
        manifest.names[s] = i
        table.insert(names, s)
      end
    end

    add_name(name)
    add_name(name:lower())
    if name:find("%.nvim$") then
      add_name(name:sub(1, -6), p)

    elseif name:find("%.vim$") then
      add_name(name:sub(1, -5), p)
    end

    if p.url then
      -- e.g. https://github.com/b0o/schemastore.nvim.git
      local user, name = p.url:match("github%.com/([^/]+)/(.+)(%.git)$")
      if user then
        -- index by {{ github.user }}/{{ github.repo }}
        add_name(user .. "/" .. name)
      end
    end
  end

  do
    local results = plugins.check()
    for i = 1, #results do
      local elem = results[i]
      local idx = assert(manifest.names[elem[1]])
      local p = assert(manifest.plugins[idx])
      p.updated = elem[2]
      p.commit = elem[3]
    end
  end

  vim.cmd.helptags(B.main .. "/doc")

  assert(fs.write_file(B.root .. "/manifest.json", vim.json.encode(manifest)))

  assert(fs.write_file(B.root .. "/manifest.txt", vim.inspect(plugins.list())))

  local ok, err = vim.uv.fs_rename(B.root, env.nvim.bundle.root)
  assert(ok, "failed renaming bundle directory: " .. tostring(err))
end

return plugins

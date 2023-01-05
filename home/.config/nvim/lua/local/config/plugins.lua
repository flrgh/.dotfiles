local g = require "local.config.globals"
local km = require "local.keymap"

local conf = {
  lockfile = g.dotfiles.config_nvim .. "/plugins.lock.json",
  colorscheme = { "tokyonight" },
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
local LATEST_STABLE = ""

local FT_ALIAS = {
  markdown = { "md", "markdown" },
  rust = { "rust", "rs" },
  sh = { "sh", "shell", "bash" },
  terraform = { "tf", "terraform" },
}

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
        ]]
      end,
    },
  },

  jq = {
    'vito-c/jq.vim',
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

  rust = {
    {
      "simrat39/rust-tools.nvim",
      -- FIXME
      enabled = false,
      dependencies = {
        "nvim-lspconfig",
      },
      build = function()
        assert(os.execute("rustup component add clippy-preview"))
      end,
      config = function()
        require("local.module").if_exists("rust-tools", function()
          require("rust-tools").setup({
            tools = {
              autoSetHints = true,
              hover_with_actions = false,
              inlay_hints = {
                show_parameter_hints = false,
                parmeter_hints_prefix = "",
                other_hints_prefix = "",
              },
            },

          })
        end)
      end,
    },
  },
}

---@type table<string, LazySpec[]>
local plugins_by_category = {
  appearance = {
    -- Color
    {
      'sainnhe/sonokai',
      enabled = false,
      init = function()
        vim.g.sonokai_style = "atlantis"
        vim.g.sonokai_better_performance = 1
      end,
      config = function()
        if true then return end
        vim.cmd.colorscheme("sonokai")
      end,
      priority = 2^16,
    },
    {
      'folke/tokyonight.nvim',
      priority = 2^16,
      lazy = false,
      config = function()
        vim.cmd.colorscheme('tokyonight')
      end,
    },

    { 'lunarvim/darkplus.nvim', lazy = true },

    -- devicon assets
    'kyazdani42/nvim-web-devicons',

    -- Nerd Fonts helper
    'lambdalisue/nerdfont.vim',

    -- tabline for neovim
    'romgrk/barbar.nvim',

    {
      'feline-nvim/feline.nvim',
      config = function()
        require("local.config.plugins.feline")
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
  },

  functions = {
    -- Buffer management
    {
      'moll/vim-bbye',
      event = { "VimEnter" },
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
      end,
      cmd = { "GFiles", "Buffers", "Rg" },
      config = function()
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
  },


  treesitter = {
    {
      'nvim-treesitter/nvim-treesitter',
      lazy = true,
      event = { "VimEnter" },
      build = function()
        require('local.config.treesitter').bootstrap()
        vim.cmd 'TSUpdateSync'
      end,
      config = function()
        require('local.config.treesitter').setup()
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      event = { "VimEnter" },
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
      dependencies = { 'nvim-lua/plenary.nvim' },
      branch = "0.1.x",
      config = function()
        require("local.config.plugins.telescope").setup()
      end,
    },

    {
      'nvim-telescope/telescope-fzf-native.nvim',
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
      dependencies = {
        'nvim-telescope/telescope.nvim',
      },
    },
  },

  -- git[hub] integration
  git = {
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',
    'rhysd/conflict-marker.vim',
    {
      'lewis6991/gitsigns.nvim',
      config = function()
        require("gitsigns").setup({
          signcolumn         = false,
          numhl              = true,
          word_diff          = false,
          current_line_blame = true,
        })
      end,
    },
  },


  editing = {
    -- auto hlsearch stuff
    {
      'romainl/vim-cool',
      event = { "VimEnter" },
    },

    -- adds some common readline key bindings to insert and command mode
    {
      'tpope/vim-rsi',
      event = { "VimEnter" },
    },

    -- auto-insert function/block delimiters
    {
      'tpope/vim-endwise',
      event = { "InsertEnter" },
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
    'lukas-reineke/indent-blankline.nvim',

    -- useful for targetting surrounding quotes/parens/etc
    {
      "kylechui/nvim-surround",
      event = { "VimEnter" },
      config = function()
        require("nvim-surround").setup()
      end,
    },

    -- align!
    {
      'junegunn/vim-easy-align',
      event = { "VimEnter" },
      config = function()
        -- Start interactive EasyAlign in visual mode (e.g. vipga)
        km.xmap.ga = '<Plug>(EasyAlign)'
        -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
        km.nmap.ga = '<Plug>(EasyAlign)'
      end,
    },

    {
      'numToStr/Comment.nvim',
      event = { "VimEnter" },
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
    },

    {
      'hrsh7th/nvim-cmp',
      event = { "InsertEnter" },
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
      event = { "VimEnter" },
      dependencies = { "neodev.nvim" },
      config = function()
        require('local.config.lsp')
        vim.cmd 'LspStart'
      end,
    },

    {
      "glepnir/lspsaga.nvim",
      branch = "main",
      config = function()
        require("lspsaga").init_lsp_saga({
          symbol_in_winbar = {
            enable = true, -- I only work on nvim 0.8
          },
          code_action_lightbulb  = {
            -- this causes some visual defects, so it's disabled
            --
            -- the sign is also displayed in the gutter, so the virtual
            -- text is redundant anyways
            virtual_text = false,
          },
        })
      end,
    },

    {
      "lewis6991/hover.nvim",
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
          -- can't use this until nvim 0.8 drops
          title = true,
        })
      end,
    },

    {
      "zbirenbaum/copilot.lua",
      event = { "VimEnter" },
      config = function()
        vim.defer_fn(function()
          require("copilot").setup()
        end, 100)
      end,
    },

    {
      "zbirenbaum/copilot-cmp",
      dependencies = { "copilot.lua" },
      config = function ()
        require("copilot_cmp").setup()
      end
    },
  },

  plumbing = {
    "folke/lazy.nvim",

    -- cache lua code
    "lewis6991/impatient.nvim",

    -- filetype detection optimization
    "nathom/filetype.nvim",
  },

  filetype = {
    -- support .editorconfig files
    'gpanders/editorconfig.nvim',

    -- direnv support and syntax hilighting
    'direnv/direnv.vim',

    -- bazel
    "bazelbuild/vim-ft-bzl",

    -- etlua template syntax support
    {
      'VaiN474/vim-etlua',
      init = function()
        vim.cmd [[au BufRead,BufNewFile *.etlua set filetype=etlua]]
      end,
    },

  },

  -- FIXME: categorize these
  ["*"] = {
    {
      'folke/which-key.nvim',
      event = { "VimEnter" },
      config = function()
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
    ft = FT_ALIAS[ft] or ft
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

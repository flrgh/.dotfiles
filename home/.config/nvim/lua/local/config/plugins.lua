local g = require "local.config.globals"


local function build_config()
  local ps = require "local.tools.plugin-snapshot"
  local fs = require "local.fs"

  if g.bootstrap then
    return {
      snapshot = fs.basename(ps.SNAPSHOT_PATH),
      snapshot_path = fs.dirname(ps.SNAPSHOT_PATH),
      display = {
        non_interactive = true,
      },
      autoremove = true,
    }
  end

  local util = require "packer.util"

  ---@type nvim.packer.config
  local config = {
    display = {
      open_fn = util.float,
    },
    profile = {
      enable = false,
      threshold = 1,
    },

    log = {
      level = (g.debug and "debug") or nil,
    },

    snapshot = fs.basename(ps.SNAPSHOT_PATH),
    snapshot_path = fs.dirname(ps.SNAPSHOT_PATH),
    autoremove = true,
  }

  return config
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

  'lewis6991/impatient.nvim',
  'nathom/filetype.nvim',

  -- adds some common readline key bindings to insert and command mode
  'tpope/vim-rsi',

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
  {
    "kylechui/nvim-surround",
    config = function()
      require("local.module").if_exists("nvim-surround", function(ns)
        ns.setup()
      end)
    end,
  },

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


  -- git[hub] integration

  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  'rhysd/conflict-marker.vim',
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require("local.module").if_exists("gitsigns", function(gs)
        gs.setup({
          signcolumn         = false,
          numhl              = true,
          word_diff          = false,
          current_line_blame = true,
        })
      end)
    end,
  },

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
  'gpanders/editorconfig.nvim',

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
  -- etlua template syntax support
  {
    'VaiN474/vim-etlua',
    config = function()
      vim.cmd [[au BufRead,BufNewFile *.etlua set filetype=etlua]]
    end,
  },

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

  {
    'L3MON4D3/LuaSnip',
    config = function()
      require("local.config.plugins.luasnip").setup()
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    requires = {
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
    "glepnir/lspsaga.nvim",
    branch = "main",
    config = function()
      require("local.module").if_exists("lspsaga", function(saga)
        saga.init_lsp_saga({
          symbol_in_winbar = {
            enable = false, -- I only work on nvim 0.8
          },
        })
      end)
    end,
  },

  -- {
  --   "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
  --   disable = true,
  --   config = function()
  --     require("local.module").if_exists("lsp_lines", function()
  --       require("lsp_lines").setup()
  --     end)
  --   end,
  -- },
  {
    "lewis6991/hover.nvim",
    config = function()
      local mod = require "local.module"
      if not mod.exists("hover") then return end

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
        title = false,
      })
    end,
  },

  {
    'mhartington/formatter.nvim',
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

  {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    branch = "0.1.x",
    config = function()
      require("local.config.plugins.telescope").setup()
    end,
  },

  {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    requires = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require("local.config.plugins.telescope").setup_fzf_native()
    end,
  },

  {
    'nvim-telescope/telescope-symbols.nvim',
    requires = {
      'nvim-telescope/telescope.nvim',
    },
  },

  {
    'folke/which-key.nvim',
    config = function()
      local mod = require "local.module"
      mod.if_exists("which-key", function()
        require("which-key").setup {}
      end)
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
      local mod = require "local.module"
      mod.if_exists("neogen", function(neogen)
        neogen.setup {
          enabled = true
        }
      end)
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local mod = require "local.module"
      mod.if_exists("lualine", function()
        mod.reload("local.config.plugins.evil_lualine")
      end)
    end,
  },

  -- lang: rust
  {
    "simrat39/rust-tools.nvim",
    run = {
      "rustup component add clippy-preview",
    },
    config = function()
      if true then return end
      require("local.module").if_exists("rust-tools", function()
        require("rust-tools").setup({
          tools = {
            autoSetHints = true,
            hover_with_actions = true,
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
}

for i = 1, #plugins do
  local plugin = plugins[i]
  if type(plugin) == "string" then
    plugin = { plugin }
    plugins[i] = plugin
  end
end

if g.bootstrap then
  vim.notify("bootstrap packer...")
  local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.notify("installing packer...")
    vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})

    vim.notify("packadd packer.nvim...")
    vim.api.nvim_command('packadd packer.nvim')
  end

  local conf = build_config()
  local snapshot = conf.snapshot_path .. "/" .. conf.snapshot

  vim.notify("reading plugin snapshot file...")
  local fs = require "local.fs"
  local data = fs.read_json_file(snapshot)
  if data then
    for _, plugin in ipairs(plugins) do
      local name = plugin.as or plugin[1]:match("[^/]+/(.+)")
      if data[name] and data[name].commit then
        plugin.commit = data[name].commit
      end
    end
  end

  local packer = require "packer"

  vim.api.nvim_create_autocmd({"User"}, {
    pattern = { "PackerComplete" },
    callback = function()
      vim.notify("...done!")
      packer.compile()
    end,
    group = vim.api.nvim_create_augroup("user-bootstrap", { clear = true }),
  })


  vim.notify("packer.startup()...")
  packer.startup({ plugins, config = conf })

  vim.notify("packer.install()")
  packer.install()

  vim.notify("almost done...")
else
  require("packer").startup({
    plugins,
    config = build_config(),
  })
end


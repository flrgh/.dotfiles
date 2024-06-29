local _M  = {}
local plugin = require "my.utils.plugin"

function _M.bootstrap()
  require('nvim-treesitter.configs').setup {
    ensure_installed = {
      "bash",
      "c",
      "c_sharp",
      "cmake",
      "comment",
      "cpp",
      "css",
      "diff",
      "git_config",
      "git_rebase",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "go",
      "gomod",
      "gosum",
      "gpg",
      "hcl",
      "html",
      "http",
      "ini",
      "java",
      "javascript",
      "json",
      "jsonc",
      "julia",
      "linkerscript",
      "lua",
      "make",
      "markdown",
      "markdown_inline",
      "objdump",
      "passwd",
      "php",
      "python",
      "query", -- parser for treesitter queries
      "regex",
      "rst",
      "rust",
      "sql",
      "ssh_config",
      "teal",
      "terraform",
      "toml",
      "tsv",
      "typescript",
      "vim",
      "vimdoc",
      "xml",
      "yaml",
      "zig",
    },
    ignore_install = {
      "swift",
    },
    sync_install = true,
    auto_install = true,
  }
end

function _M.setup()
  require('nvim-treesitter.configs').setup {
    ensure_installed = {},
    ignore_install = {},
    sync_install = false,
    auto_install = false,
    highlight = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "ss",

        node_incremental = "+",
        node_decremental = "-",

        scope_incremental = "++",
      },
    },
    indent = {
      enable = false,
      disable = {
        "lua", -- 2021-01-02: treesitter overindents tables
      }
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  }

  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldnestmax = 3
  vim.opt.foldminlines = 4

  if plugin.installed("nvim-treesitter-context") then
    require("treesitter-context").setup{
       -- Enable this plugin (Can be enabled/disabled later via commands)
      enable = true,
      -- How many lines the window should span. Values <= 0 mean no limit.
      max_lines = 0,
       -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      min_window_height = 0,
      line_numbers = true,
       -- Maximum number of lines to show for a single context
      multiline_threshold = 20,
       -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      trim_scope = "outer",
      -- Line used to calculate context. Choices: 'cursor', 'topline'
      mode = "cursor",
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = "-",
      -- The Z-index of the context window
      zindex = 20,
      -- (fun(buf: integer): boolean) return false to disable attaching
      on_attach = nil,
    }
  end
end

return _M

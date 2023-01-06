local _M  = {}

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
      "go",
      "gomod",
      "hcl",
      "java",
      "javascript",
      "json",
      "jsonc",
      "lua",
      "markdown",
      "php",
      "python",
      "query", -- parser for treesitter queries
      "regex",
      "rust",
      "rst",
      "teal",
      "toml",
      "typescript",
      "vim",
      "yaml",
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
end

return _M

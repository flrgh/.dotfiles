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
end

return _M

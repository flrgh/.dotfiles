if require("local.config.globals").bootstrap then
  return
end

if not pcall(require, 'nvim-treesitter') then
  return
end

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
  auto_install = true,
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
  }
}

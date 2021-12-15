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
    "regex",
    "rust",
    "rst",
    "teal",
    "toml",
    "typescript",
    "yaml",
  },
  highlight = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  indent = {
    enable = false,
    disable = {
      "lua", -- 2021-01-02: treesitter overindents tables
    }
  }
}

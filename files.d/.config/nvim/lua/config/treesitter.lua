require('nvim-treesitter.configs').setup {
    ensure_installed = "maintained",
    highlight = {
        enable = true,
    },
    incremental_selection = {
        enable = true,
    },
    indent = {
        enable = false,
        disable = {
            "lua", -- 2021-01-02: treesitter overindents tables
        }
    }
}

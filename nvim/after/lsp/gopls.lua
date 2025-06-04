---@type vim.lsp.Config
return {
  settings = {
    gopls = {
      buildFlags = {
        "-tags=integration",
      },
      gofumpt = true,
    },
  }
}

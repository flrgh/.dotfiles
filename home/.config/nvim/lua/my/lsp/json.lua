return {
  init = function()
    return {
      -- for some reason lspconfig has this as
      -- `vscode-json-language-server` instead of `vscode-json-languageserver`
      cmd = { "vscode-json-languageserver", "--stdio" },
    }
  end,
}

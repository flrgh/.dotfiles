local json = {
  schemas = nil,
  validate = { enable = false },
}

if require("my.utils.plugin").installed("schemastore") then
  local ss = require "schemastore"
  json.schemas = ss.json.schemas()
  json.validate.enable = true
end

return {
  -- for some reason lspconfig has this as
  -- `vscode-json-language-server` instead of `vscode-json-languageserver`
  cmd = { "vscode-json-languageserver", "--stdio" },
  settings = {
    json = json,
  },
}

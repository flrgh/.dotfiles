local _M = {}

local lsp = vim.lsp
local vim = vim

_M.hover = function()
  return lsp.buf.hover({
    border = "rounded"
  })
end

_M.code_action         = lsp.buf.code_action
_M.declaration         = lsp.buf.declaration
_M.definition          = lsp.buf.definition
_M.implementation      = lsp.buf.implementation
_M.references          = lsp.buf.references
_M.rename              = lsp.buf.rename
_M.show_diagnostic     = vim.diagnostic.open_float
_M.signature_help      = lsp.buf.signature_help
_M.type_definition     = lsp.buf.type_definition

return _M

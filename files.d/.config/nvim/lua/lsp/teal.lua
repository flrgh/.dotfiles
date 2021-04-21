local lspconfig = require("lspconfig")

return function(on_attach, lsp, caps)
  if not vim.fn.executable("teal-language-server") then
    return
  end

  -- Make sure this is a slash (as theres some metamagic happening behind the scenes)
  local configs = require("lspconfig/configs")
  configs.teal = {
    default_config = {
      cmd = {
        "teal-language-server",
        -- "logging=on", use this to enable logging in /tmp/teal-language-server.log
      },
      filetypes = { "teal" };
      root_dir = lspconfig.util.root_pattern("tlconfig.lua", ".git"),
      settings = {};
    },
  }

  lspconfig.teal.setup({})
end

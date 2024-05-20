local lsp = require "lspconfig"

-- Make sure this is a slash (as theres some metamagic happening behind the scenes)
require("lspconfig.configs").tealls = {
  default_config = {
    cmd = {
      "teal-language-server",
      -- "logging=on", use this to enable logging in /tmp/teal-language-server.log
    },
    filetypes = { "teal" };
    root_dir = lsp.util.root_pattern("tlconfig.lua", ".git"),
    settings = {}
  },
}

return {}

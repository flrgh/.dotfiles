if require("my.constants").bootstrap then
  return
end

return require("my.lsp.lua_ls").init()

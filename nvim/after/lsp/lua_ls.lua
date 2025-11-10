if require("my.env").bootstrap then
  return
end

return require("my.lsp.lua_ls").init()

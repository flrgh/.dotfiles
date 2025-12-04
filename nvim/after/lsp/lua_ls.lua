if not require("my.env").editor then
  return
end

return require("my.lsp.lua_ls").init()

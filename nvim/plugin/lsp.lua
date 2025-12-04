if not require("my.env").editor then
  return
end

if vim.g.loaded_my_lsp then
  return
end

vim.g.loaded_my_lsp = true


require("my.lsp").init()

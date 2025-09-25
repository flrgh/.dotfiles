local lua_resolve = require("my.fn.lua_resolve")

vim.api.nvim_buf_create_user_command(
  0,
  "Resolve",
  lua_resolve.resolve,
  {
    desc = "Resolve a lua module",
    nargs = "?",
    complete = lua_resolve.complete,
  }
)

vim.api.nvim_buf_create_user_command(
  0,
  "Resolve",
  function(...)
    return require("my.fn.lua_resolve").resolve(...)
  end,
  {
    desc = "Resolve a lua module",
    nargs = "?",
    complete = function()
      return require("my.fn.lua_resolve").complete(0)
    end,
  }
)

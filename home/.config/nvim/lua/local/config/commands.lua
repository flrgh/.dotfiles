local add_command = vim.api.nvim_create_user_command

add_command("Dump",
  "lua vim.pretty_print(<args>)",
  { nargs = 1,
    complete = "lua",
    force = true,
  }
)

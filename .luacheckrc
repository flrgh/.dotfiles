std = "luajit"

not_globals = {
    "string.len",
    "table.getn",
}

files["nvim/**/*.lua"] = {
  globals = {
    "vim",
  }
}

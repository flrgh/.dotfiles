local opt_local = vim.opt_local

-- make $ a keyword
opt_local.iskeyword:append("$")

-- force utf-8
opt_local.fileencoding = "utf-8"

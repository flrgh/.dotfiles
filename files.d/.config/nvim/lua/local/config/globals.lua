do
  local fs = require 'local.fs'

  local ws = fs.workspace_root()
  if ws then
    vim.fn.setenv("NVIM_WORKSPACE", ws)
  end
end

if vim.g.loaded_workspace_rc then
  return
end

vim.g.loaded_workspace_rc = true

local event = require("my.event")

-- XXX: is VimEnter too late?
event.on(event.VimEnter)
  :desc("load per-workspace rc file (./.nvim.lua)")
  :group("user-workspace-rc", true)
  :once(true)
  :callback(function()
    require("my.fn.load_workspace_rc")()
  end)

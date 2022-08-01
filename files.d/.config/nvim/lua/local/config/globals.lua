local globals = {}

--- nvim workspace directory
---@type string
globals.workspace = nil

do
  local mod = require "local.module"
  local ws

  if mod.exists("lspconfig") then
    local util = require "lspconfig.util"
    local f = vim.fn.expand("%:p:h")
    ws = util.find_git_ancestor(f)
  end

  local fs = require 'local.fs'
  if not ws then
    ws = fs.workspace_root()
  end

  if not ws then
    ws = fs.buffer_directory()
  end

  if ws then
    vim.fn.setenv("NVIM_WORKSPACE", ws)
    globals.workspace = ws
  end
end


--- LSP debug enabled
---@type boolean
globals.lsp_debug = false

do
  local env = os.getenv("NVIM_LSP_DEBUG")
  if env and env ~= "0" then
    globals.lsp_debug = true

    -- vim.log.levels.TRACE will show even more info but has not been all that
    local level = vim.log.levels[env] or vim.log.levels.DEBUG

    vim.lsp.set_log_level(level)

    -- omit the metatable from vim.inspect outoupt
    local inspect = vim.inspect
    local METATABLE = inspect.METATABLE
    local opts = {
      process = function(item, path)
        if path[#path] ~= METATABLE then return item end
      end
    }

    require("vim.lsp.log").set_format_func(function(item)
      return inspect(item, opts)
    end)
  end
end

---@type boolean
globals.debug = false
do
  local env = os.getenv("NVIM_DEBUG")
  if env and env ~= "0" then
    globals.debug = true
  end
end

return globals

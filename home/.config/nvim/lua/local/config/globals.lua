---@class user.globals
local globals = {}

---@param path string
---@return string expanded
local function expand(path)
  local res = vim.fn.expand(path, nil, false)
  if not res then
    vim.notify("could not expand path (" .. path .. ")")
    return path
  end
  return res
end

local function detect_workspace()
  local mod = require "local.module"
  local fs = require 'local.fs'
  local ws

  if mod.exists("lspconfig") then
    local util = require "lspconfig.util"
    local f = vim.fn.expand("%:p:h")
    ws = util.find_git_ancestor(f)
  end

  return ws
      or fs.workspace_root()
      or fs.buffer_directory()
      or vim.loop.cwd()
      or vim.fn.getenv("PWD")
end


--- nvim workspace directory
---@type string
globals.workspace = detect_workspace()
if globals.workspace then
  vim.fn.setenv("NVIM_WORKSPACE", globals.workspace)
end


--- LSP debug enabled (based on `NVIM_LSP_DEBUG=1`)
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


--- Debug flag (based on the value of `NVIM_DEBUG=1`)
---@type boolean
globals.debug = false
do
  local env = os.getenv("NVIM_DEBUG")
  if env and env ~= "0" then
    globals.debug = true
  end
end


--- My github username
---@type string
globals.github_username = "flrgh"


--- Path to ~/git
---@type string
globals.git_root = expand("~/git")


--- Path to ~/git/{{github_username}}
---@type string
globals.git_user_root = globals.git_root .. "/" .. globals.github_username


do
  local dotfiles = globals.git_user_root .. "/.dotfiles"
  local config_nvim = dotfiles .. "/home/.config/nvim"

  --- Special locations within my dotfiles repo
  ---@class user.globals.dotfiles
  globals.dotfiles = {
    --- Absolute to my dotfiles repo (~/git/flrgh/.dotfiles)
    ---@type string
    root = dotfiles,

    --- Path to ~/.config/nvim _within_ my dotfiles repo
    ---@type string
    config_nvim = config_nvim,

    --- Path to ~/.config/nvim/lua _within_ my dotfiles repo
    ---@type string
    config_nvim_lua = config_nvim .. "/lua",

  }
end

---@type boolean
globals.bootstrap = (_G.___BOOTSTRAP and true)
                    or os.getenv("NVIM_BOOTSTRAP") == "1"

return globals

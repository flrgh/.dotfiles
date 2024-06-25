---@class user.globals
local globals = {}

local getenv = os.getenv
local vim = vim

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
  local mod = require "my.utils.luamod"
  local fs = require "my.utils.fs"
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
  local env = getenv("NVIM_LSP_DEBUG")
  if env and env ~= "0" then
    globals.lsp_debug = true

    local level = vim.log.levels[env] or vim.log.levels.DEBUG
    vim.lsp.set_log_level(level)

    local logger = require "my.lsp.logger"
    logger.init()
    vim.lsp.log.set_format_func(logger.log)
    vim.schedule(function()
      vim.notify("LSP debugging enabled. Log file:\n" .. logger.fname)
    end)
  end
end


--- Debug flag (based on the value of `NVIM_DEBUG=1`)
---@type boolean
globals.debug = false
do
  local env = getenv("NVIM_DEBUG")
  if env and env ~= "0" then
    globals.debug = true
    vim.schedule(function()
      vim.notify("Neovim debug enabled via `NVIM_DEBUG` var")
    end)
  end
end


globals.home = getenv("HOME") or expand("~")

--- My github username
---@type string
globals.github_username = "flrgh"

--- Path to ~/git
---@type string
globals.git_root = globals.home .. "/git"


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

do
  local app_name = getenv("NVIM_APPNAME") or "nvim"
  local share = getenv("XDG_DATA_HOME") or (globals.home .. "/.local/share")
  local config = getenv("XDG_CONFIG_HOME") or (globals.home .. "/.local/config")
  local state = getenv("XDG_STATE_HOME") or (globals.home .. "/.local/state")

  ---@class user.globals.nvim
  globals.nvim = {
    -- $NVIM_APPNAME (default "nvim")
    app_name = app_name,

    -- ~/.local/config/nvim
    config      = config .. "/" .. app_name,

    -- ~/.local/share/nvim
    share       = share .. "/" .. app_name,

    -- ~/.local/state/nvim
    state       = state .. "/" .. app_name,

    -- ~/.local/share/nvim/runtime
    runtime     = share .. "/" .. app_name .. "/runtime",

    -- ~/.local/share/nvim/runtime/lua
    runtime_lua = share .. "/" .. app_name .. "/runtime/lua",

    -- plugin install path
    -- ~/.local/share/nvim/lazy
    plugins = share .. "/" .. app_name .. "/lazy",
  }
end


---@type boolean
globals.bootstrap = (_G.___BOOTSTRAP and true)
                    or getenv("NVIM_BOOTSTRAP") == "1"

return globals

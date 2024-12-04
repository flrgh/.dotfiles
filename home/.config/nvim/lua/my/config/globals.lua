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

    require("my.lsp.logger").init()
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
  local home = assert(globals.home)

  ---@class user.globals.xdg
  globals.xdg = {
    -- $XDG_DATA_HOME (~/.local/share)
    data = getenv("XDG_DATA_HOME") or (home .. "/.local/share"),

    -- $XDG_CONFIG_HOME (~/.config)
    config = getenv("XDG_CONFIG_HOME") or (home .. "/.config"),

    -- $XDG_STATE_HOME (~/.local/state)
    state = getenv("XDG_STATE_HOME") or (home .. "/.local/state"),

    -- $XDG_CACHE_HOME (~/.cache)
    cache = getenv("XDG_CACHE_HOME") or (home .. "/.cache"),
  }
end

do
  local app_name = getenv("NVIM_APPNAME") or "nvim"

  local xdg = globals.xdg

  ---@class user.globals.nvim
  globals.nvim = {
    -- $NVIM_APPNAME (default "nvim")
    app_name = app_name,

    -- ~/.config/nvim
    config = xdg.config .. "/" .. app_name,

    -- ~/.local/share/nvim
    share = xdg.data .. "/" .. app_name,

    -- ~/.local/state/nvim
    state = xdg.state .. "/" .. app_name,

    -- ~/.local/share/nvim/runtime
    runtime = xdg.data .. "/" .. app_name .. "/runtime",

    -- ~/.local/share/nvim/runtime/lua
    runtime_lua = xdg.data .. "/" .. app_name .. "/runtime/lua",

    -- plugin install path
    -- ~/.local/share/nvim/lazy
    plugins = xdg.data .. "/" .. app_name .. "/lazy",
  }
end

---@type boolean
globals.bootstrap = (_G.___BOOTSTRAP and true)
                    or getenv("NVIM_BOOTSTRAP") == "1"

return globals

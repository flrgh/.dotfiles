---@class my.constants
local const = {}

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
  local fs = require "my.utils.fs"

  return vim.fs.root(0, ".git")
      or fs.workspace_root()
      or fs.buffer_directory()
      or vim.uv.cwd()
      or vim.fn.getenv("PWD")
end


--- nvim workspace directory
---@type string
const.workspace = detect_workspace()
if const.workspace then
  vim.fn.setenv("NVIM_WORKSPACE", const.workspace)
end

---@type integer
const.lsp_log_level = vim.log.levels.OFF

--- LSP debug enabled (based on `NVIM_LSP_DEBUG=1`)
---@type boolean
const.lsp_debug = false
do
  local env = getenv("NVIM_LSP_DEBUG")
  if env and env ~= "0" then
    const.lsp_debug = true
    const.lsp_log_level = vim.log.levels.DEBUG
  end
end


--- Debug flag (based on the value of `NVIM_DEBUG=1`)
---@type boolean
const.debug = false
do
  local env = getenv("NVIM_DEBUG")
  if env and env ~= "0" then
    const.debug = true
    vim.schedule(function()
      vim.notify("Neovim debug enabled via `NVIM_DEBUG` var")
    end)
  end
end


--- `$(whoami)`
---@type string
const.username = getenv("USER")
                or getenv("LOGNAME")
                or getenv("USERNAME")
                or vim.system({ "whoami" })
                   :wait()
                   .stdout
                   :gsub("[\r\n]*$", "")

const.home = getenv("HOME")
            or expand("~")
            or ("/home/" .. const.username)

--- My github username
---@type string
const.github_username = "flrgh"

--- Path to ~/git
---@type string
const.git_root = const.home .. "/git"

--- Path to ~/git/{{github_username}}
---@type string
const.git_user_root = const.git_root .. "/" .. const.github_username

do
  local dotfiles = const.git_user_root .. "/.dotfiles"
  local config_nvim = dotfiles .. "/nvim"

  --- Special locations within my dotfiles repo
  ---@class user.globals.dotfiles
  const.dotfiles = {
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
  local home = assert(const.home)

  ---@class user.globals.xdg
  const.xdg = {
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

  local xdg = const.xdg

  ---@class user.globals.nvim
  const.nvim = {
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
const.bootstrap = (_G.___BOOTSTRAP and true)
                    or getenv("NVIM_BOOTSTRAP") == "1"

return const

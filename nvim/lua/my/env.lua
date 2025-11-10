---@class my.env
local env = {}

local getenv = os.getenv
local vim = vim
local uv = vim.uv
local api = vim.api
local expand = vim.fn.expand
local log_levels = vim.log.levels
local select = select

--- My github username
---@type string
env.github_username = "flrgh"


--- directory nvim was launched from
---@type string
env.cwd = assert(uv.cwd() or getenv("PWD"),
                 "could not detect process working directory")

do
  local fs_stat = uv.fs_stat

  local cwd = env.cwd
  local buf_dir = expand("%:p:h", true, false)

  local git_root
  local parent = buf_dir or cwd
  while parent and parent ~= "/" and parent ~= "" do
    local git_dir = parent .. "/.git"
    local stat, _, e = fs_stat(git_dir)

    if stat and stat.type == "directory" then
      git_root = parent
      break
    elseif e and e ~= "ENOENT" then
      error("unexpected FS error while stat-ing " .. git_dir
            .. ": " .. tostring(e))
    end

    parent = parent:gsub("/+[^/]*$", "")
  end

  --- nvim workspace directory
  ---@type string
  env.workspace = git_root or buf_dir or cwd
  vim.fn.setenv("NVIM_WORKSPACE", env.workspace)
end

---@type integer
env.lsp_log_level = vim.log.levels.OFF

--- LSP debug enabled (based on `NVIM_LSP_DEBUG=1`)
---@type boolean
env.lsp_debug = false
do
  local var = getenv("NVIM_LSP_DEBUG")
  if var and var ~= "0" then
    env.lsp_debug = true
    env.lsp_log_level = log_levels.DEBUG
  end
end


--- Debug flag (based on the value of `NVIM_DEBUG=1`)
---@type boolean
env.debug = false
do
  local var = getenv("NVIM_DEBUG")
  if var and var ~= "0" then
    env.debug = true
    vim.schedule(function()
      vim.notify("Neovim debug enabled via `NVIM_DEBUG` var",
                 log_levels.INFO)
    end)
  end
end

do
  local username = getenv("USER")
                  or getenv("LOGNAME")
                  or getenv("USERNAME")

  if not username then
    username = vim.system({ "logname" })
      :wait()
      .stdout
      :gsub("[\r\n]*$", "")
  end

  --- `$(whoami)`
  ---@type string
  env.username = assert(username, "failed to detect username")
end

env.home = getenv("HOME")
            or expand("~", nil, false)
            or ("/home/" .. env.username)

--- My github username
---@type string
env.github_username = "flrgh"

--- Path to ~/git
---@type string
env.git_root = env.home .. "/git"

--- Path to ~/git/{{github_username}}
---@type string
env.git_user_root = env.git_root .. "/" .. env.github_username

do
  local dotfiles = env.git_user_root .. "/.dotfiles"
  local config_nvim = dotfiles .. "/nvim"

  --- Special locations within my dotfiles repo
  ---@class user.globals.dotfiles
  env.dotfiles = {
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
  local home = assert(env.home)

  ---@class user.globals.xdg
  env.xdg = {
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

  local xdg = env.xdg

  local share_nvim = xdg.data .. "/" .. app_name
  local bundle = share_nvim .. "/_bundle"

  ---@class user.globals.nvim
  env.nvim = {
    -- $NVIM_APPNAME (default "nvim")
    app_name = app_name,

    -- ~/.config/nvim
    config = xdg.config .. "/" .. app_name,

    -- ~/.local/share/nvim
    share = share_nvim,

    -- ~/.local/state/nvim
    state = xdg.state .. "/" .. app_name,

    -- ~/.local/share/nvim/runtime
    runtime = share_nvim .. "/runtime",

    -- ~/.local/share/nvim/runtime/lua
    runtime_lua = share_nvim .. "/runtime/lua",

    -- plugin install path
    -- ~/.local/share/nvim/lazy
    plugins = share_nvim .. "/lazy",

    -- bundle directory
    --
    -- at the moment this is only used for lua path things
    bundle = {
      -- ~/.local/share/nvim/_bundle
      root = bundle,

      -- ~/.local/share/nvim/_bundle/lua
      lua = bundle .. "/lua",
    },
  }
end

---@alias my.env.mode
---| "editor"
---| "bootstrap"
---| "pager"
---| "script"

---@type my.env.mode
env.mode = "editor"

---@type boolean
env.bootstrap = false

---@type boolean
env.headless = false

---@type boolean
env.editor = false

---@type boolean
env.pager = false

---@type boolean
env.script = false

do
  ---@generic T any
  ---@param ...(T|nil)
  ---@return T|nil
  local function first_non_nil(...)
    local n = select("#", ...)

    local value
    for i = 1, n do
      value = select(i, ...)
      if value ~= nil then
        return value
      end
    end
  end

  ---@param mode any
  ---@param ctx string
  ---@return my.env.mode|nil
  local function check_valid_mode(mode, ctx)
    if not (mode == nil
        or mode == "editor"
        or mode == "pager"
        or mode == "bootstrap"
      )
    then
      vim.notify("unknown value for " .. ctx ..
                 ": '" .. tostring(mode) .. "'",
                 log_levels.WARN)

      mode = nil
    end
    return mode
  end

  ---@class my.env.init
  ---@field mode?      my.env.mode

  ---@param params? my.env.init|my.env.mode
  function env.init(params)
    local mode
    if type(params) == "table" then
      mode = params.mode
    elseif params then
      assert(type(params) == "string")
      mode = params
    end

    do
      local uis = api.nvim_list_uis()
      if uis then
        env.headless = #uis == 0
      end
    end

    -- default mode value
    if env.headless then
      env.mode = "script"
    else
      env.mode = "editor"
    end

    local g = vim.g

    mode = first_non_nil(
      check_valid_mode(mode, "params.mode"),
      check_valid_mode(g.my_env_mode, "g:my_env_mode"),
      check_valid_mode(getenv("NVIM_ENV_MODE"), "NVIM_ENV_MODE"),
      env.mode
    )

    env.mode = mode
    g.my_env_mode = mode

    env.editor = false
    env.bootstrap = false
    env.pager = false
    env.script = false

    if mode == "editor" then
      env.editor = true
    elseif mode == "bootstrap" then
      env.bootstrap = true
    elseif mode == "pager" then
      env.pager = true
    elseif mode == "script" then
      env.script = true
    else
      error("unreachable")
    end
  end
end

setmetatable(env, {
  __index = function(_, key)
    error("trying to get undefined env key '" .. tostring(key) .. "'")
  end,

  __newindex = function(_, key)
    error("trying to set undefined env key '" .. tostring(key) .. "'")
  end,
})

env.init()

return env

---@class my.workspace : table
---
---@field dir string # fully-qualified workspace directory path
---@field basename string # last path element of the workspace
---@field meta my.workspace.meta
local WS = {}


local fs = require "my.std.fs"
local env = require "my.env"

--- annotations from https://github.com/LuaCATS
local LUA_CATS = env.git_root .. "/LuaCATS"
local LUA_TYPE_ANNOTATIONS = env.git_user_root .. "/lua-type-annotations"


local insert = table.insert

---@alias my.workspace.meta table<string, any>

---@alias my.workspace.matcher fun(ws: my.workspace):boolean|nil


---@param subject string
---@param sub string
---@return boolean
local function substr(subject, sub)
  return subject:find(sub, nil, true) ~= nil
end


---@type my.workspace.matcher[]
local matchers = {
  -- lua_ls
  function(ws)
    if ws.basename == "lua-language-server" then
      ws.meta.lua = true
      ws.meta.luarc = true
      return true
    end
  end,
}

if not WS.dir then
  local dir = assert(env.workspace)
  assert(fs.dir_exists(dir))

  WS.dir = assert(fs.realpath(dir))
  WS.basename = fs.basename(dir)
  WS.meta = {}
  WS.lsp = {}

  for i = 1, #matchers do
    if matchers[i](WS) then
      break
    end
  end
end

return WS

---Lua Module Utils.
---@module "my.utils.module"
local _M = {}

local pcall = pcall
local require = require

---Forcibly reload a module
---@param name string
---@return any
function _M.reload(name)
  _G.package.loaded[name] = nil
  return require(name)
end

---Check if a module exists
---@param name string
---@return boolean
function _M.exists(name)
  local exists = pcall(require, name)
  return (exists and true) or false
end

---Run a function if a module exists.
---@param  name string
---@param  cb?  fun(mod: any)
---@return any
function _M.if_exists(name, cb)
  local exists, mod = pcall(require, name)

  if exists then
    if cb then cb(mod) end
    return mod
  end

  if mod:find(name, nil, true) and mod:find('not found', nil, true) then
    return
  else
    error("Failed loading module (" .. name .. "): " .. mod)
  end
end

return _M

local _M = {}

local path = require("my.std.path")

---@class my.workspace
---
---@field dir string # fully-qualified workspace directory path
---@field basename string # last path element of the workspace
---@field meta table<string, any>
local WS = {}
local MT = { __index = WS }


---@param dir string
---@return my.workspace
function WS.from_dir(dir)
  assert(path.dir_exists(dir))

  dir = assert(path.realpath(dir))

  local ws = {
    dir = dir,
    basename = path.basename(dir),
    meta = {},
  }

  setmetatable(ws, MT)

  return ws
end


---@param fname string
---@return my.workspace
function WS.from_file(fname)
  local dir = path.dirname(fname)
  return WS.from_dir(dir)
end


---@param dir string
---@param git? boolean
---@return my.workspace
function _M.root(dir, git)
  local ws = WS.from_dir(dir)
  ws.meta.root = true
  ws.meta.git = git or false
  return ws
end


return _M

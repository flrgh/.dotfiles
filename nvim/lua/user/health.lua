local _M = {}

local insert = table.insert
local fmt = string.format
local select = select

---@type { [string]: user.health.namespace }
local STATUS = {}

---@alias user.health.namespace user.health.entry[]

---@alias user.health.entry [user.health.status, string]

---@alias user.health.status 0|1|2

local OK = 0
local WARN = 1
local ERR = 2

---@return user.health.namespace
local function getns(ns)
  STATUS[ns] = STATUS[ns] or {}
  return STATUS[ns]
end


local function report(status, ns, msg, ...)
  if select("#", ...) > 0 then
    msg = fmt(msg, ...)
  end

  ns = getns(ns)
  insert(ns, { status, msg })
end


---@param ns string
---@param msg string
---@param ... any
function _M.ok(ns, msg, ...)
  report(OK, ns, msg, ...)
end


---@param ns string
---@param msg string
---@param ... any
function _M.warn(ns, msg, ...)
  report(WARN, ns, msg, ...)
end


---@param ns string
---@param msg string
---@param ... any
function _M.error(ns, msg, ...)
  report(ERR, ns, msg, ...)
end


function _M.check()
  ---@type string[]
  local keys = {}
  for name in pairs(STATUS) do
    insert(keys, name)
  end
  table.sort(keys)

  for _, name in ipairs(keys) do
    local status = STATUS[name]
    vim.health.start(name)

    for _, entry in ipairs(status) do
      local state = entry[1]
      local msg = entry[2]

      if state == OK then
        vim.health.ok(msg)

      elseif state == WARN then
        vim.health.warn(msg)

      else
        vim.health.error(msg)
      end
    end
  end
end


return _M

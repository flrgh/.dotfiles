local _M = {}

---@type any, Lazy
local _, lazy = pcall(require, "lazy")

---@type table<string, LazyPlugin>
local by_name

---@type LazyPlugin[]
local list

local function _index()
  if list then return end

  by_name = {}
  list = {}

  ---@param name string
  ---@param p LazyPlugin
  local function add_name(name, p)
    local current = by_name[name]
    if current and current ~= p then
      error("name collision for plugins " .. p.name .. " and " .. current.name)
    end
    by_name[name] = p
  end

  ---@param name string
  ---@param p LazyPlugin
  local function add(name, p)
    assert(type(name) == "string")
    assert(type(p) == "table")

    add_name(name, p)
    add_name(name:lower(), p)

    if name:find("%.nvim$") then
      add(name:sub(1, -6), p)

    elseif name:find("%.vim$") then
      add(name:sub(1, -5), p)
    end
  end

  for _, p in ipairs(lazy.plugins()) do
    -- index by name
    add(p.name, p)

    if p.url then
      -- e.g. https://github.com/b0o/schemastore.nvim.git
      local user, name = p.url:match("github%.com/([^/]+)/(.+)(%.git)$")
      if user then
        -- index by {{ github.user }}/{{ github.repo }}
        add(user .. "/" .. name, p)
      end
    end

    table.insert(list, p)
  end
end

---@param name string
---@return LazyPlugin? plugin
---@return string? error
function _M.get(name)
  if not lazy then
    return nil, "lazy.nvim is not loaded"
  end

  _index()

  local plugin = by_name[name] or by_name[name:lower()]
  if plugin then
    return plugin
  end

  return nil, "plugin not found"
end

---@param name string
---@return boolean
function _M.installed(name)
  return _M.get(name) ~= nil
end

---@return LazyPlugin[]
function _M.list()
  if not lazy then
    return {}
  end

  _index()

  return list
end

return _M

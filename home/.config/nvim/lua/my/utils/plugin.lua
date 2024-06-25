local _M = {}

---@type any, Lazy
local _, lazy = pcall(require, "lazy")

---@type table<string, LazyPlugin>
local by_name

---@type LazyPlugin[]
local list

---@param name string
---@return LazyPlugin? plugin
---@return string? error
function _M.get(name)
  if not lazy then
    return nil, "lazy.nvim is not loaded"
  end

  if not by_name then
    by_name = {}
    list = {}

    for _, p in ipairs(lazy.plugins()) do
      -- index by name
      by_name[p.name] = p

      -- index by lowercase name
      local name_lc = p.name:lower()
      by_name[name_lc] = by_name[name_lc] or p

      -- index by {{ github.user }}/{{ github.repo }}
      local repo = p[1]
      if type(repo) == "string" then
        by_name[repo] = p
      end

      table.insert(list, p)
    end
  end

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

  return list
end

return _M

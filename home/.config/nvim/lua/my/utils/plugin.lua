local _M = {}

---@type any, Lazy
local _, lazy = pcall(require, "lazy")

---@param name string
---@return LazyPlugin? plugin
---@return string? error
function _M.get(name)
  if not lazy then
    return nil, "lazy.nvim is not loaded"
  end

  for _, p in ipairs(lazy.plugins()) do
    if p.name == name then
      return p
    end
  end

  return nil, "plugin not found"
end

---@param name string
---@return boolean
function _M.installed(name)
  return _M.get(name) ~= nil
end

return _M

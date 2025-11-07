local _M = {}

local luamod = require("my.std.luamod")
local storage = require("my.storage")
local km = require("my.keymap")

local default_resolver

local api = vim.api
local trim = vim.trim
local WARN = vim.log.levels.WARN

local min = math.min
local max = math.max
local floor = math.floor
local gsub = string.gsub
local fmt = string.format


---@param s string
---@return string
local function strip(s)
  return (gsub(s, "^%s*([^%s]+).*", "%1"))
end


function _M.resolve(args)
  local name = strip(args.args or "")

  if name == "" then
    name = luamod.requires.get_line_requires()
  end

  if not name then
    vim.notify("resolve(): empty module name", WARN)
    return
  end

  local resolver = storage.buffer.lua_resolver
  if not resolver then
    default_resolver = default_resolver or luamod.resolver.default()
    resolver = default_resolver
    storage.buffer.lua_resolver = resolver
  end

  local mod, tried = resolver:find_module(name, true)

  local lines

  if mod then
    lines = {
      fmt("  module:  %q  ", name),
      fmt("  file:    %q  ", mod.fname),
      fmt("  tree:    %q  ", mod.tree.dir),
      fmt("  abspath: %q  ", mod.tree.dir .. "/" .. mod.fname),
      fmt("  src:     %q  ", mod.tree.meta.source),
    }
  else
    lines = {
      fmt("  module:  %q  ", name),
      "  (not found)  ",
      "  tried:  ",
    }

    for i = 1, #tried do
      table.insert(lines, fmt("  - %q  ", tried[i]))
    end
  end


  local float = api.nvim_create_buf(false, true)

  local height = #lines
  local width = 80

  for i = 1, height do
    width = max(width, #lines[i])
  end

  api.nvim_buf_set_lines(float, 0, -1, true, lines)

  local win = api.nvim_get_current_win()
  local win_height = api.nvim_win_get_height(win)
  local win_width = api.nvim_win_get_width(win)

  km.normal.on("q")
    :buffer(float)
    :desc("close")
    :callback(function(...)
      api.nvim_buf_delete(float, { force = true })
    end)

  api.nvim_open_win(float, true, {
    relative = "win",
    col = floor((win_width / 2) - (width / 2)),
    row = floor((win_height / 2) - (height / 2)),

    width = width,
    height = height,


    title = fmt("require(%q)", name),
    footer = "(Press `q` to close)",

    noautocmd = true,

    mouse = true,

    style = "minimal",
    border = { "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" },
  })
end


---@param buf? integer
---@return string[]
function _M.complete(buf)
  buf = buf or 0
  return luamod.get_module_requires(buf)
end


return _M

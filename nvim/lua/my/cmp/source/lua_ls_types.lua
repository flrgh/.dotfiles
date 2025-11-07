local const = require("my.constants")
local cmp = require("cmp")
local storage = require("my.storage")
local std = require("my.std")
local luamod = std.luamod
local plugin = std.plugin

local vim = vim
local fmt = string.format
local TRIGGER_CHARS = { " ", "." }
local NAME = "lua_ls_types"

---@class my.cmp.source.lua_ls_types
local source = {}
local SOURCE_MT = { __index = source }

source.NAME = NAME

---@type fun(my.lua_ls.Config): lsp.CompletionItem[]
local find_all_types
do
  ---@type { [integer]: lsp.CompletionItem[] }
  local _TYPES = {}

  local function cmp_types(a, b)
    return a.label < b.label
  end

  ---@param config my.lua_ls.Config
  local function populate_types(config)
    if _TYPES[config.id] then
      return
    end

    local extra_paths = {}
    local seen = {}
    local function add(path)
      if not path then
        return
      end

      if not seen[path] then
        seen[path] = true
        table.insert(extra_paths, path)
      end
    end

    add(config:lls_meta_dir())
    add(config.config.root_dir)
    add(require("my.workspace").dir)

    if config.meta.neovim then
      for _, d in ipairs(plugin.lua_dirs()) do
        add(d)
      end
      add(const.nvim.runtime)
    end

    local defs = luamod.find_all_types(extra_paths)

    ---@type lsp.CompletionItem[]
    local types = std.table.new(#defs, 0)

    for i = 1, #defs do
      local def = defs[i]
      local doc = fmt(
[[# %s (%s)

[source](file://%s)
line %s

```lua
%s
```
]], def.name, def.label, def.source, def.line_number, def.lines)

      ---@type lsp.CompletionItem
      local item = {
        label = def.name,
        documentation = {
          kind = cmp.lsp.MarkupKind.Markdown,
          value = doc,
        },
        kind = cmp.lsp.CompletionItemKind.Class,
        data = def,
      }
      types[i] = item
    end

    table.sort(types, cmp_types)

    -- don't unlock or store until done processing
    _TYPES[config.id] = types
  end

  ---@param config my.lua_ls.Config
  ---@return nil|lsp.CompletionItem[]
  function find_all_types(config)
    local types = _TYPES[config.id]
    if types then
      return types
    end

    config:with_mutex("lua_ls_types.find_all_types", populate_types)

    return nil
  end
end



function source.new()
  local self = setmetatable({}, SOURCE_MT)
  return self
end

---@return string
function source:get_debug_name()
  return NAME
end

---@return boolean
function source:is_available()
  return vim.bo.filetype == 'lua'
end

---@param _cfg cmp.SourceConfig
---@return string
function source:get_keyword_pattern(_cfg)
  return [[\w\+]]
end

-- just for self documentation
source.get_keyword_pattern = nil

---@param _cfg cmp.SourceConfig
---@return string[]
function source:get_trigger_characters(_cfg)
  return TRIGGER_CHARS
end

---@return lsp.PositionEncodingKind
function source:get_position_encoding_kind()
end

-- just for self documentation
source.get_position_encoding_kind = nil

local function is_class_or_alias(def)
  local typ = def.label
  return typ == "class" or typ == "alias"
end

---@param params cmp.SourceCompletionApiParams
---@param callback fun(items: lsp.CompletionResponse|nil)
function source:complete(params, callback)
  local config = storage.buffer.lua_lsp
  if not config then
    callback()
    return
  end

  local line = params.context.cursor_before_line

  local label, rest = line:match("%-%-%-%s*@(%w+)%s+(.*)")
  if not label
    or not (
      label == "alias" or
      label == "type" or
      label == "param" or
      label == "return" or
      label == "field" or
      label == "class"
    )
  then
    callback()
    return
  end

  local filter_text, filter_func
  if label == "param" or label == "alias" or label == "field" then
    filter_text = rest:match("^[^%s]+%s+(.*)")

  elseif label == "class" then
    filter_text = rest:match("^[^%s]+%s*:%s+(.*)")
    filter_func = is_class_or_alias

  else
    filter_text = rest:match("^([^%s]*)")
  end

  if not filter_text then
    callback()
    return
  end

  local types = find_all_types(config)
  if not types then
    callback({ isIncomplete = true, items = nil })
    return
  end

  if filter_text ~= "" then
    local filtered = {}
    local n = 0
    for i = 1, #types do
      local ty = types[i]
      if ty.label:find(filter_text, 1, true) == 1 then
        n = n + 1
        filtered[n] = ty
      end
    end
    types = filtered
  end

  if filter_func then
    local filtered = {}
    local n = 0
    for i = 1, #types do
      local ty = types[i]
      if filter_func(ty.data) then
        n = n + 1
        filtered[n] = ty
      end
    end
    types = filtered
  end

  callback({ items = types })
end

---@param _item lsp.CompletionItem
---@param callback fun(item: lsp.CompletionItem|nil)
function source:resolve(_item, callback)
  callback()
end


---@param item lsp.CompletionItem
---@param callback function
function source:execute(item, callback)
  local config = storage.buffer.lua_lsp
  if not config then
    callback()
    return
  end

  local data = item.data
  if not data then
    callback()
    return
  end

  config:add_workspace_library(data.tree)
  callback()
  config:update_client_settings()
end

return source

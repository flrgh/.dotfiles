local vim = vim
local startswith = vim.startswith
local endswith   = vim.endswith
local nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
local nvim_set_keymap = vim.api.nvim_set_keymap
local fmt = string.format

local _M = {}

local CR = "<CR>"

_M.CR       = CR
_M.Return   = CR
_M.Enter    = CR

_M.Delete = "<Del>"
_M.End    = "<End>"
_M.Escape = "<Esc>"
_M.Help   = "<Help>"
_M.Home   = "<Home>"
_M.Insert = "<Insert>"
_M.Undo   = "<Undo>"

_M.NOP      = "<NOP>"
_M.EOL      = "<EOL>"

_M.F1       = "<F1>"
_M.F2       = "<F2>"
_M.F3       = "<F3>"
_M.F4       = "<F4>"
_M.F5       = "<F5>"
_M.F6       = "<F6>"
_M.F7       = "<F7>"
_M.F8       = "<F8>"
_M.F9       = "<F9>"
_M.F10      = "<F10>"
_M.F11      = "<F11>"
_M.F12      = "<F12>"

_M.PageUp   = "<PageUp>"
_M.PageDown = "<PageDown>"

_M.Tab      = "<Tab>"
_M.Space    = "<Space>"

_M.Up       = "<Up>"
_M.Down     = "<Down>"
_M.Left     = "<Left>"
_M.Right    = "<Right>"

---@param a table
---@param b table
---@return table
local function extend(a, b)
  if not a then
    return b
  elseif not b then
    return a
  end

  return vim.tbl_deep_extend("force", a, b)
end

---@param mode string
---@param key string
---@param action string
---@param opts? vim.api.keyset.keymap
---@param buf? boolean
local function create_keymap(mode, key, action, opts, buf)
  if buf then
    return nvim_buf_set_keymap(0, mode, key, action, opts)
  else
    return nvim_set_keymap(mode, key, action, opts)
  end
end

local EMPTY = {}

---@param v any
---@return boolean
local function is_callable(v)
  local typ = type(v)

  if typ == "function" then
    return true

  elseif typ == "string" then
    return false

  elseif v == nil then
    return false
  end

  return type(getmetatable(v) or EMPTY).__call == "function"
end


local mt = {
  __newindex = function(self, key, v)
    if v == nil then
      return
    end

    local action = v
    local opts

    if type(v) == 'table' then
      action = v[1]
      v[1] = nil
      opts = v
    end

    opts = opts or {}

    if action == nil then
      return
    end

    opts.desc = opts.desc or opts[2]
    opts[2] = nil

    if is_callable(action) then
      opts = vim.deepcopy(opts)
      opts.callback = action
      action = ""
    end

    if not opts.no_auto_cr then
      -- auto-append Enter/<CR> to commands
      if startswith(action, ':') then
        if not endswith(action:upper(), CR) then
          action = action .. CR
        end
      end
    end

    opts.no_auto_cr = nil

    return create_keymap(
      self.mode or '',
      key,
      action,
      extend(self.opts, opts),
      self.buf
    )
  end
}


---@alias my.keymap.mode "n"|"v"|"x"|""

---@class my.keymap.opts : vim.api.keyset.keymap
---
---@field buf?        boolean
---@field no_auto_cr? boolean

---@class my.keymap.action.table : my.keymap.opts
---@field [1] string|function # the RHS of the key map
---@field [2] string|nil      # shorthand for desc = ...

---@alias my.keymap.action string|my.keymap.action.table

---@alias my.keymap.binding table<string, my.keymap.action>

---@class my.keymap : table
---@field ctrl     my.keymap.binding
---@field fn       my.keymap.binding
---@field leader   my.keymap.binding
---@field mode     my.keymap.mode
---@field opts     my.keymap.opts


---@param mode string
---@param opts my.keymap.opts
---@return my.keymap.binding
local function make_map(mode, opts)
  local buf = opts.buf
  opts.buf = nil
  return setmetatable({
    mode = mode,
    opts = opts,
    buf  = buf,
  }, mt)
end

_M.map      = make_map('',  { noremap = false })
_M.vmap     = make_map('v', { noremap = false })
_M.nmap     = make_map('n', { noremap = false })
_M.noremap  = make_map('',  { noremap = true })
_M.vnoremap = make_map('v', { noremap = true })
_M.nnoremap = make_map('n', { noremap = true })
_M.xmap     = make_map('x', { noremap = false })
_M.imap     = make_map('i', { noremap = false })
_M.smap     = make_map('s', { noremap = false })

-- for setting buffer-specific mappings
_M.buf = {
  map      = make_map('',  { buf = true, noremap = false }),
  vmap     = make_map('v', { buf = true, noremap = false }),
  nmap     = make_map('n', { buf = true, noremap = false }),
  noremap  = make_map('',  { buf = true, noremap = true }),
  vnoremap = make_map('v', { buf = true, noremap = true }),
  nnoremap = make_map('n', { buf = true, noremap = true }),
  xmap     = make_map('x', { buf = true, noremap = false }),
  imap     = make_map('i', { buf = true, noremap = false }),
  smap     = make_map('s', { buf = true, noremap = false }),
}

--- Generate a Ctrl+<key> key binding
---
--- Example:
--- ```lua
--- print(Ctrl.t) -- > `<C-t>`
--- ```
---
---@type table<string, string>
_M.Ctrl = setmetatable({}, {
  __index = function(_, k)
    assert(type(k) == "string" or type(k) == "number")
    return fmt("<C-%s>", k)
  end,
})

--- Generate a Shift+<key> key binding
---
--- Example:
--- ```lua
--- print(Shift.Tab) -- > `<S-Tab>`
--- ```
---
---@type table<string, string>
_M.Shift = setmetatable({}, {
  __index = function(_, k)
    assert(type(k) == "string" or type(k) == "number")
    return fmt("<S-%s>", k)
  end,
})


--- Generate a Leader-prefixed string
---
--- Example:
--- ```lua
--- print(Leader.t) -- > `<Leader>t`
--- ```
---
---@type table<string, string>
_M.Leader = setmetatable({}, {
  __index = function(_, k)
    assert(type(k) == "string" or type(k) == "number")
    return fmt("<Leader>%s", k)
  end,
})

return _M

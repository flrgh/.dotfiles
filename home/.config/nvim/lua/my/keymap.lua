local vim = vim
local startswith = vim.startswith
local endswith   = vim.endswith
local nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
local nvim_set_keymap = vim.api.nvim_set_keymap

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

local function create_keymap(mode, key, action, opts, buf)
  if buf then
    return nvim_buf_set_keymap(0, mode, key, action, opts)
  else
    return nvim_set_keymap(mode, key, action, opts)
  end
end

local mt = {
  __newindex = function(self, key, v)
    if v == nil then
      return
    end

    if self.set_key then
      key = self.set_key(key)
    end

    local action = v
    local opts

    if type(v) == 'table' then
      action = v[1]
      v[1] = nil
      opts = v
    end


    opts = opts or {}

    if type(action) == "function" then
      opts = vim.deepcopy(opts)
      opts.callback = action
      action = ""
    end

    if not opts.no_auto_cr then
      -- auto-append <CR> to commands
      if startswith(action, ':') then
        if not endswith(action:upper(), '<CR>') then
          action = action .. '<CR>'
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

---@param t string
---@return my.keymap.set_key
local function template(t)
  return function(key)
    return t:format(key)
  end
end

local wrap_ctrl = template('<C-%s>')
local wrap_fn = template('<%s>')
local add_leader = template('<Leader>%s')

---@alias my.keymap.set_key fun(s:string):string

---@alias my.keymap.mode '"n"'|'"v"'|'"x"'|'""'

---@class my.keymap.opts : table
---@field noremap boolean
---@field silent  boolean
---@field nowait  boolean
---@field script  boolean
---@field expr    boolean
---@field unique  boolean

---@class my.keymap.action.table : my.keymap.opts
---@field [1] string # the RHS of the key map

---@alias my.keymap.action string|my.keymap.action.table

---@alias my.keymap.binding table<string, my.keymap.action>

---@class my.keymap : table
---@field ctrl     my.keymap.binding
---@field fn       my.keymap.binding
---@field leader   my.keymap.binding
---@field mode     my.keymap.mode
---@field opts     my.keymap.opts
---@field set_key? my.keymap.set_key

---@return my.keymap
local function make_map(mode, opts)
  local buf = opts.buf
  opts.buf = nil
  return setmetatable({
    mode = mode,
    opts = opts,
    buf  = buf,

    ctrl = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_ctrl,
        buf     = buf,
      },
      mt
    ),

    fn = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_fn,
        buf     = buf,
      },
      mt
    ),

    leader = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = add_leader,
        buf     = buf,
      },
      mt
    ),
  }, mt)
end

local map      = make_map('',  { noremap = false })
local vmap     = make_map('v', { noremap = false })
local nmap     = make_map('n', { noremap = false })
local noremap  = make_map('',  { noremap = true })
local vnoremap = make_map('v', { noremap = true })
local nnoremap = make_map('n', { noremap = true })
local xmap     = make_map('x', { noremap = false })
local imap     = make_map('i', { noremap = false })
local smap     = make_map('s', { noremap = false })

local buf = {
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

---@type table<string, string>
local ctrl = setmetatable({}, {
  __index = function(_, k)
    return wrap_ctrl(k)
  end,
})

return {
  map  = map,
  nmap = nmap,
  vmap = vmap,
  xmap = xmap,
  imap = imap,
  smap = smap,

  noremap  = noremap,
  nnoremap = nnoremap,
  vnoremap = vnoremap,

  buf = buf,

  setup = function(fn)
    fn(map, nmap, vmap, noremap, nnoremap, vnoremap, xmap)
  end,


  Ctrl  = ctrl,
  Enter = '<CR>',
  Tab   = '<Tab>',
  S_Tab = '<S-Tab>',
  Leader = '<leader>',
}

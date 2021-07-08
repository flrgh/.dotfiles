local keymap = vim.api.nvim_set_keymap

local function extend(...)
  local new = {}
  for i = 1, select('#', ...) do
    local t = select(i, ...)
    if type(t) == 'table' then
      for k, v in pairs(t) do new[k] = v end
    end
  end
  return new
end

local mt = {
  __newindex = function(self, key, v)
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

    -- auto-append <CR> to commands
    if action:sub(1, 1) == ':' then
      if action:sub(-4):upper() ~= '<CR>' then
        action = action .. '<CR>'
      end
    end

    keymap(
      self.mode or '',
      key,
      action,
      extend(self.opts, opts)
    )
  end
}

local function template(t)
  return function(key)
    return t:format(key)
  end
end

local wrap_ctrl = template('<C-%s>')
local wrap_fn = template('<%s>')
local add_leader = template('<Leader>%s')

local function make_map(mode, opts)
  return setmetatable({
    mode = mode,
    opts = opts,

    ctrl = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_ctrl,
      },
      mt
    ),

    fn = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_fn,
      },
      mt
    ),

    leader = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = add_leader,
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

return {
  map  = map,
  nmap = nmap,
  vmap = vmap,

  noremap  = noremap,
  nnoremap = nnoremap,
  vnoremap = vnoremap,

  setup = function(fn)
    fn(map, nmap, vmap, noremap, nnoremap, vnoremap)
  end,
}

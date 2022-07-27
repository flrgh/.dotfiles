local create_augroup = vim.api.nvim_create_augroup
local create_autocmd = vim.api.nvim_create_autocmd

local fmt = string.format

---@class vim.autocmd.event
---@field id    number
---@field event string
---@field match string expanded value of <amatch>
---@field buf   number expanded value of <abuf>
---@field file  string expanded value of <afile>

---@class vim.autocmd.command
---@field desc     string
---@field event    string
---@field events   string[]
---@field pattern  string
---@field buffer   number
---@field callback fun(event:vim.autocmd.event):boolean
---@field command  string
---@field once     boolean
---@field nested   boolean

---@param name string
---@param cmds vim.autocmd.command[]
local function create(name, cmds)
  local gid = create_augroup(name, {})
  for i, cmd in ipairs(cmds) do
    local opts = {
      group    = gid,
      pattern  = cmd.pattern,
      buffer   = cmd.buffer,
      desc     = cmd.desc or fmt("%s autocmd %s/%s", name, i, #cmds),
      callback = cmd.callback,
      command  = cmd.command,
      once     = cmd.once,
      nested   = cmd.nested,
    }

    local evt = cmd.event or cmd.events
    create_autocmd(evt, opts)
  end
end

do
  create("user-nomodified", {
    {
      desc = "Manage fileencoding + modifiable + modified",
      events = {"BufNewFile", "BufRead"},
      pattern = "*",
      callback = function()
        local bo = vim.bo

        -- IDK why this is necessary, but setting buffer `fileencoding` for the
        -- first time always sets `modified`, so this forcibly sets it and
        -- then resets `nomodified`
        if not bo.fileencoding or bo.fileencoding == "" then
          bo.fileencoding = "utf-8"
          bo.modified = false
        end

        -- when run with -R, set `nomodifiable`
        if vim.o.readonly then
          bo.modifiable = false
        end
      end,
    },

    {
      desc = "Set nomodified+nomodifiable when reading from stdin",
      event = "StdinReadPost",
      pattern = "*",
      callback = function()
        vim.bo.modifiable = false
        vim.bo.modified = false
      end,
    },
  })
end

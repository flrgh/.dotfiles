local event = require("my.event")

if false then
  require("vim.wut")
end

local encode = vim.json.encode
local write = vim.uv.fs_write
local assert = assert

local fname = "./events.log"
local fd = assert(vim.uv.fs_open(fname, "w+", tonumber(0644, 8)))

event.on(event.NON_CMD_EVENTS)
  :group("user-event-debug", true)
  :nested(true)
  :callback(function(e)
    if not fd then
      return
    end
    assert(write(fd, encode(e) .. "\n"))

    if e.event == event.VimLeavePre then
      vim.uv.fs_fsync(fd)
      vim.uv.fs_close(fd)
      fd = nil
    end
  end)

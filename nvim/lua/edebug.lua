local event = require("my.event")

local encode = vim.json.encode
local write = vim.uv.fs_write
local assert = assert
local update_time = vim.uv.update_time
local now = vim.uv.now

local fname = "./events.log"
local fd = assert(vim.uv.fs_open(fname, "w+", tonumber(0644, 8)))

event.on(event.NON_CMD_EVENTS)
  :group("user-event-debug", true)
  :nested(true)
  :callback(function(e)
    if not fd then
      return
    end
    if e.event == event.SafeState then
      return
    end

    update_time()
    e.time = now() / 1000

    assert(write(fd, encode(e) .. "\n"))

    if e.event == event.VimLeavePre then
      vim.uv.fs_fsync(fd)
      vim.uv.fs_close(fd)
      fd = nil
    end
  end)

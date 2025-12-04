--local fname = "./events.log"
--local fd = assert(vim.uv.fs_open(fname, "w+", tonumber(0644, 8)))
--local closing = false

local queue = assert(vim.uv.new_work(
  function(entry)
    local state = require("my.state").global

    if entry == false or state.closing then
      state.closing = true
      return
    end

    --local infos = require("inspect")(_G.vim)
    --assert(vim.uv.fs_write(fd, infos .. "\n"))

    local fd = vim.uv.fs_open("./events.log", "a+", tonumber(0644, 8))
    if fd then
      vim.uv.fs_write(fd, entry .. "\n")
      vim.uv.fs_fsync(fd)
      vim.uv.fs_close(fd)
    end
  end,
  function() end
))

local event = require("my.event")

local closing = false
local encode = vim.json.encode
local write = vim.uv.fs_write
local update_time = vim.uv.update_time
local now = vim.uv.now


event.on(event.NON_CMD_EVENTS)
  :group("user-event-debug", true)
  :nested(true)
  :callback(function(e)
    if closing or e.event == event.SafeState then
      return
    end

    update_time()
    e.time = now() / 1000

    --assert(write(fd, encode(e) .. "\n"))
    queue:queue(encode(e))

    if e.event == event.VimLeavePre then
      queue:queue(false)
      closing = true
    end
  end)

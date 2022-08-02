local globals = require "local.config.globals"
local fs = require "local.fs"

local FNAME = globals.dotfiles.config_nvim .. "/packer-snapshot.json"
local BACKUP = FNAME .. ".bak"


local JQ_ARGS = {
  "-S", -- sort keys
  "-M"  -- monochrome (no color)
}


local vim = vim
local uv = vim.loop
local unlink = uv.fs_unlink
local fmt = string.format
local file_exists = fs.file_exists
local rename = fs.rename

--- packer plugin snapshot utils
local _M = {
  --- absolute path to snapshot file
  SNAPSHOT_PATH = FNAME,

  --- absolute path to snapshot backup file
  SNAPSHOT_BACKUP_PATH = BACKUP,
}

local function format_file()
  local contents = assert(fs.read_file(FNAME))

  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local buf = {}
  local handle

  local function close()
    if handle then uv.close(handle) end
  end

  local function on_finish(code, signal)
    if code ~= 0 then
      vim.schedule(function()
        close()
        vim.notify(fmt("jq exited with error (%s) from signal (%s)", code, signal))
      end)
      return
    end

    vim.schedule(function()
      close()

      local ok, err = fs.write_file(FNAME, buf)
      local reset = false
      if ok then
        vim.notify("Reformat of " .. FNAME .. " complete")
      else
        vim.notify("Failed writing to snapshot file: " .. err)
        reset = true
      end

      if file_exists(BACKUP) then
        if reset then
          rename(BACKUP, FNAME)
        else
          uv.fs_unlink(BACKUP)
        end
      end
    end)
  end

  handle = uv.spawn("jq", {
    args = JQ_ARGS,
    stdio = { stdin, stdout, stderr },
  }, on_finish)

  assert(uv.write(stdin, contents))
  assert(uv.shutdown(stdin))

  uv.read_start(stderr, function(err, data)
    assert(err == nil, "Error reading stderr: " .. tostring(err))
    if data then
      vim.notify("stderr: " .. data)
    end
  end)

  uv.read_start(stdout, function(err, data)
    assert(err == nil, "Error reading stdout: " .. tostring(err))
    if data then
      table.insert(buf, data)
    end
  end)
end


function _M.snapshot()
  local ok, err = true, nil

  if file_exists(BACKUP) then
    ok, err = unlink(BACKUP)
  end

  if not ok then return nil, err end

  if file_exists(FNAME) then
    ok, err = rename(FNAME, BACKUP)
  end

  if not ok then return nil, err end

  local poll = uv.new_fs_poll()

  uv.fs_poll_start(poll, FNAME, 500, function(e, _, cur)
    if e then
      return

    elseif not (cur and cur.ino and cur.ino > 0) then
      return
    end

    poll:stop()
    vim.schedule(format_file)
  end)

  require("packer").snapshot(FNAME)
end

return _M

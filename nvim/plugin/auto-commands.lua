if require("my.constants").bootstrap then
  return
end

local event = require("my.event")
local vim = vim

event.on({ event.BufNewFile, event.BufRead })
  :group("user-nomodified", true)
  :pattern("*")
  :desc("Manage fileencoding + modifiable + modified")
  :callback(function(e)
    local bo = vim.bo[e.buf]

    -- IDK why this is necessary, but setting buffer `fileencoding` for the
    -- first time always sets `modified`, so this forcibly sets it and
    -- then resets `nomodified`
    if not bo.fileencoding or bo.fileencoding == "" then
      if bo.modifiable then
        bo.fileencoding = "utf-8"
        bo.modified = false
      end
    end

    -- when run with -R, set `nomodifiable`
    if vim.o.readonly then
      bo.modifiable = false
    end
  end)

event.on({ event.StdinReadPost })
  :group("user-nomodified-stdin", true)
  :pattern("*")
  :desc("Set nomodified+nomodifiable when reading from stdin")
  :callback(function(e)
    local bo = vim.bo[e.buf]
    bo.modifiable = false
    bo.modified = false
  end)

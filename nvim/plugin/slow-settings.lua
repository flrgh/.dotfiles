-- settings that are important but require some OS probing
-- and thus shouldn't block the main thread during init

do
  local env = require("my.env")
  local bash = env.home .. "/.local/bin/bash"

  if vim.o.shell ~= bash then
    local o = vim.o

    vim.uv.fs_access(bash, "rx", function(_err, perm)
      if not perm then
        return
      end

      if not vim.in_fast_event() then
        vim.schedule(function()
          o.shell = bash
        end)

      else
        o.shell = bash
      end
    end)
  end
end

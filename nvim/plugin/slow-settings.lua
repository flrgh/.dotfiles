-- settings that are important but require some OS probing
-- and thus shouldn't block the main thread during init

do
  local bash = os.getenv("HOME") .. "/.local/bin/bash"

  if vim.o.shell ~= bash then
    vim.uv.fs_access(bash, "rx", function(_err, perm)
      if not perm then
        return
      end

      if vim.in_fast_event() then
        vim.schedule(function()
          vim.o.shell = bash
          vim.env.SHELL = bash
        end)

      else
        vim.o.shell = bash
        vim.env.SHELL = bash
      end
    end)
  end
end

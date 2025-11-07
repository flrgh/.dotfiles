local const = require("my.constants")
local fs = require("my.std.fs")

-- https://lazy.folke.io/configuration
---@type LazyConfig
local conf = require("my.lazy.config")

local lazypath = conf.root .. "/lazy.nvim"

if not fs.exists(lazypath) then
  local notify = const.bootstrap and print or vim.notify

  local on_stdout, on_stderr
  if const.bootstrap then
    on_stdout = function(err, data)
      if err then
        notify("STDOUT (error): " .. err)
      elseif data then
        notify("STDOUT : " .. data)
      end
    end

    on_stderr = function(err, data)
      if err then
        notify("STDERR (error): " .. err)
      elseif data then
        notify("STDERR : " .. data)
      end
    end
  end

  notify("installing plugin manager (lazy.nvim)")

  local res = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }, {
    text = true,
    stdout = on_stdout,
    stderr = on_stderr,
  }):wait()
  assert(res.code == 0)
end

vim.opt.runtimepath:prepend(lazypath)

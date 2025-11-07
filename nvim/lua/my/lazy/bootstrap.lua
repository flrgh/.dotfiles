---@param mode? "verbose"|"quiet"|"silent"
return function(mode)
  mode = mode or "verbose"
  local silent = mode == "silent"
  local quiet = silent or mode == "quiet"

  local vim = vim

  if not silent then
    vim.print("Bootstrapping plugins\n")
  end

  if quiet then
    require("my.std.io").pause()
  end

  vim.go.loadplugins = true

  local conf = require("my.lazy.config")
  local plugins = require("my.plugins")
  local lazy = require("lazy")


  -- block until the entire restore task completes
  conf.wait = true

  conf.spec = plugins
  lazy.setup(conf)
  lazy.restore(conf)
  lazy.build(conf)

  if quiet then
    require("my.std.io").unpause()
  end

  if not silent then
    vim.print("Plugin bootstrap complete\n")
  end
end

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

  require("my.plugins").load(true)

  if quiet then
    require("my.std.io").unpause()
  end

  require("my.plugins").bundle()

  if not silent then
    vim.print("Plugin bootstrap complete\n")
  end
end

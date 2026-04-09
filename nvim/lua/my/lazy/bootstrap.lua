---@param mode? "verbose"|"quiet"|"silent"
return function(mode)
  mode = mode or "verbose"
  local silent = mode == "silent"
  local quiet = silent or mode == "quiet"

  if not silent then
    io.write("Bootstrapping plugins\n")
  end

  if quiet then
    require("my.std.io").pause()
  end

  require("my.plugins").bootstrap()

  if quiet then
    require("my.std.io").unpause()
  end

  require("my.plugins").bundle()

  if not silent then
    io.write("Plugin bootstrap complete\n")
  end
end

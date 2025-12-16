local lua_ls = require("my.lsp.lua_ls")
lua_ls.update(function(conf)
  local env = require("my.env")
  local plugins = require("my.plugins")
  local path  = require("my.std.path")

  local PLUGINS = {
    "lazy.nvim",
    "nvim-cmp",
    "nvim-lspconfig",
    "blink.cmp",
  }

  local dotfiles = env.dotfiles
  conf:prepend_runtime_dir(dotfiles.nvim_lua)
      :add_workspace_library(dotfiles.nvim_lua)
      :set_root_dir(dotfiles.nvim)

  for _, plugin_name in ipairs(PLUGINS) do
    local plug = plugins.get(plugin_name)
    if plug and plug.dir and plug.dir ~= "" then
      conf:add_library(plug.dir .. "/lua", {
        source = "plugin",
        plugin = plug.name,
      })
    end
  end

  if path.dir_exists(env.nvim.bundle.lua) then
    conf:add_runtime_dir(env.nvim.bundle.lua)
  else
    for _, lua in ipairs(plugins.lua_dirs()) do
      if path.dir_exists(lua) then
        conf:add_runtime_dir(lua)
      end
    end
  end

  lua_ls.hooks.on_lua_module("vim", conf)
end)

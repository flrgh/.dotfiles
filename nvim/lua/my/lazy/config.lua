local const = require("my.constants")
local fs = require("my.std.fs")

-- https://lazy.folke.io/configuration
---@type LazyConfig
local conf = {
  lockfile = fs.join(const.dotfiles.config_nvim, "plugins.lock.json"),
  root = const.nvim.plugins,

  defaults = {
  },

  pkg = {
    -- we'll see...
    enabled = false,
  },

  install = {
    -- install missing plugins on startup
    missing = true,
  },

  change_detection = {
    enabled = false,
  },

  performance = {
    cache = {
      enabled = true,
    },

    reset_packpath = true,

    rtp = {
      reset = true,
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "rplugin",
        "spellfile",
        "tarPlugin",
        "tutor",
        "zipPlugin",
      },
    },
  },

  profiling = {
    loader  = const.debug,
    require = const.debug,
  },
}

return conf

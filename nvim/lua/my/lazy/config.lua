local env = require("my.env")

-- https://lazy.folke.io/configuration
---@type LazyConfig
local conf = {
  lockfile = env.dotfiles.nvim .. "/plugins.lock.json",
  root = env.nvim.plugins,

  defaults = {
  },

  pkg = {
    enabled = false,
  },

  rocks = {
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
    loader  = env.debug,
    require = env.debug,
  },

  spec = nil,

  -- don't load /.lazy.lua files
  local_spec = false,

  checker = {
    enabled = false,
  },

  readme = {
    enabled = true,
  },
}

return conf

return {
  init = function()
    local schemaStore, schemas

    local mod = require "my.utils.luamod"
    if mod.exists("schemastore") then
      local ss = require "schemastore"

      schemaStore = {
        enable = false,
        url = "",
      }

      schemas = ss.yaml.schemas()
    end

    return {
      settings = {
        yaml = {
          keyOrdering = false,
          schemaStore = schemaStore,
          schemas = schemas,
        },
        redhat = {
          telemetry = {
            enabled = false,
          },
        },
      }
    }
  end,
}

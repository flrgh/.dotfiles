local schemaStore
local schemas

if require("my.utils.plugin").installed("schemastore") then
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

local schemaStore
local schemas

if require("my.utils.plugin").installed("schemastore") then
  local ss = require "schemastore"

  schemaStore = {
    enable = false,
    url = "",
  }

  schemas = ss.yaml.schemas({
    extra = {
      {
        description = "ast-grep rule",
        name = "rule.yml",
        fileMatch = {
          -- this matches kong & kong-ee layouts
          "ast-grep/rules/*.yml",
        },
        url = "https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json",
      },
      {
        description = "ast-grep project config",
        name = "sgconfig.yml",
        fileMatch = { "sgconfig.yml", "sgconfig.yaml" },
        url = "https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/project.json",
      },
    },
  })
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

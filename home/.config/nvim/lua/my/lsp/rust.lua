local function enable(t)
  t = t or {}
  t.enable = true
  return t
end

local function disable(t)
  t = t or {}
  t.enable = false
end

return {
  -- https://github.com/rust-lang/rust-analyzer/blob/master/docs/user/generated_config.adoc
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = true,
      check = {
        command = "clippy",
        extraArgs = {
          "--no-deps",
          "--",
          "-D",
          "warnings",
        },
      },
      completion = {
        autoimport = enable(),
        autoself = enable(),
      },
      hover = {
        actions = {
          enable = true,
          debug = enable(),
          references = enable(),
          memoryLayout = disable(),
        },
      },
      inlayHints = {
        bindingModeHints = enable(),
      },
      interpret = {
        tests = true,
      },
      cargo = {
        features = "all",

        autoreload = true,

        buildScripts = enable(),
      },
    },
  },
}

local function enable(t)
  t = t or {}
  t.enable = true
  return t
end

local function disable(t)
  t = t or {}
  t.enable = false
  return t
end

return {
  settings = {
    -- https://rust-analyzer.github.io/manual.html#configuration
    ["rust-analyzer"] = {
      assist = {
        expressionFillDefault = nil, -- default
      },

      cargo = {
        features     = "all",
        autoreload   = true,
        buildScripts = enable(),
      },

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
        autoself   = enable(),
        postfix    = enable(),
      },

      diagnostics = {
        styleLints = enable(),
      },

      hover = {
        actions = enable({
          debug           = enable(),
          gotoTypeDef     = enable(),
          implementations = enable(),
          run             = enable(),
          references      = enable(),
        }),

        documentation = enable({
          keywords = enable(),
        }),

        memoryLayout = disable(),

        show = {
          enumVariants    = 5,
          fields          = 5,
          traitAssocItems = 5,
        },
      },

      imports = {
        preferPrelude = true,
      },

      inlayHints = {
        bindingModeHints = enable(),
        chainingHints    = enable(),
        typeHints = enable(),
      },

      interpret = {
        tests = true,
      },

      lens = enable({
        debug           = enable(),
        implementations = enable(),
        references      = {
          enumVariant = enable(),
          method      = enable(),
          trait       = enable(),
        },
        run           = enable(),
      }),

      procMacro = enable({
        attributes = enable(),
      }),
    },
  },
}

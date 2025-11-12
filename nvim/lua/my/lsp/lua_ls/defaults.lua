local const = require("my.lsp.lua_ls.constants")

local ApplyInMemory = const.ApplyInMemory
local Disable = const.Disable
local Enable = const.Enable
local Fallback = const.Fallback
local Opened = const.Opened
local None = const.None

local insert = table.insert

---@class my.lsp.config.Lua: vim.lsp.Config
local defaults = {
  cmd = nil,
  root_dir = nil,
  settings = {
    ---@type my.lsp.LuaLS
    Lua = {
      completion = {
        enable           = true,

        autoRequire      = false,
        callSnippet      = Disable,
        displayContext   = 0, -- disabled
        keywordSnippet   = Disable,
        postfix          = "@",
        requireSeparator = ".",
        showParams       = true,
        showWord         = Fallback,
        workspaceWord    = false,
      },

      diagnostics = {
        enable = false,
        disable = nil,

        globals = {
          'vim',

          -- openresty/kong globals
          'ngx',
          'kong',

          -- busted globals
          'after_each',
          'before_each',
          'describe',
          'expose',
          'finally',
          'insulate',
          'it',
          'lazy_setup',
          'lazy_teardown',
          'mock',
          'pending',
          'pending',
          'randomize',
          'setup',
          'spec',
          'spy',
          'strict_setup',
          'strict_teardown',
          'stub',
          'teardown',
          'test',

        },

        ignoredFiles = Disable,
        libraryFiles = Disable,
        workspaceDelay = 3000,
        workspaceRate = 100,
        workspaceEvent = "OnSave",

        unusedLocalExclude = {
          "self",
        },

        neededFileStatus = {
          -- group: ambiguity
          ["ambiguity-1"]        = Opened,
          ["count-down-loop"]    = None,
          ["different-requires"] = None,
          ["newline-call"]       = None,
          ["newfield-call"]      = None,

          -- group: await
          ["await-in-sync"] = None,
          ["not-yieldable"] = None,

          -- group: codestyle
          ["codestyle-check"]  = None,
          ["name-style-check"] = None,
          ["spell-check"]      = None,

          -- group: conventions
          ["global-element"] = Opened,

          -- group: duplicate
          ["duplicate-index"]        = Opened,
          ["duplicate-set-field"]    = Opened,

          -- group: global
          ["global-in-nil-env"]      = None,
          ["lowercase-global"]       = None,
          ["undefined-env-child"]    = None,
          ["undefined-global"]       = Opened,

          -- group: luadoc
          ["cast-type-mismatch"]       = Opened,
          ["circle-doc-class"]         = None,
          ["doc-field-no-class"]       = Opened,
          ["duplicate-doc-alias"]      = Opened,
          ["duplicate-doc-field"]      = Opened,
          ["duplicate-doc-param"]      = Opened,
          ["incomplete-signature-doc"] = Opened,
          ["missing-global-doc"]       = None,
          ["missing-local-export-doc"] = None,
          ["undefined-doc-class"]      = Opened,
          ["undefined-doc-name"]       = Opened,
          ["undefined-doc-param"]      = Opened,
          ["unknown-cast-variable"]    = Opened,
          ["unknown-diag-code"]        = Opened,
          ["unknown-operator"]         = Opened,

          -- group: redefined
          ["redefined-local"]        = Opened,

          -- group: strict
          ["close-non-object"]       = None,
          ["deprecated"]             = Opened,
          ["discard-returns"]        = None,

          -- group: strong
          ["no-unknown"] = None,

          -- group: type-check
          ["assign-type-mismatch"] = Opened,
          ["cast-local-type"]      = Opened,
          ["inject-field"]         = Opened,
          ["need-check-nil"]       = Opened,
          ["param-type-mismatch"]  = Opened,
          ["return-type-mismatch"] = Opened,
          ["undefined-field"]      = Opened,

          -- group: unbalanced
          ["missing-fields"]         = Opened,
          ["missing-parameter"]      = Opened,
          ["missing-return"]         = Opened,
          ["missing-return-value"]   = Opened,
          ["redundant-parameter"]    = Opened,
          ["redundant-return-value"] = Opened,
          ["redundant-value"]        = Opened,
          ["unbalanced-assignments"] = Opened,

          -- group: unused
          ["code-after-break"] = Opened,
          ["empty-block"]      = None,
          ["redundant-return"] = None,
          ["trailing-space"]   = None,
          ["unreachable-code"] = Opened,
          ["unused-function"]  = Opened,
          ["unused-label"]     = Opened,
          ["unused-local"]     = Opened,
          ["unused-vararg"]    = Opened,
        }
      },

      doc = {
        packageName = nil,
        privateName = nil,
        protectedName = nil,
        regengine = "glob",
      },

      format = {
        defaultConfig = nil,
        enable = false,
      },

      hint = {
        enable         = true,

        arrayIndex     = Enable,
        await          = true,
        awaitPropagate = true,
        paramName      = const.All,
        paramType      = true,
        semicolon      = Disable,
        setType        = true,
      },

      hover = {
        enable        = true,

        enumsLimit    = 10,
        expandAlias   = false,
        previewFields = 20,
        viewNumber    = true,
        viewString    = true,
        viewStringMax = 1000,
      },

      IntelliSense = {
        -- https://github.com/sumneko/lua-language-server/issues/872
        traceLocalSet    = true,
        traceReturn      = true,
        traceBeSetted    = true,
        traceFieldInject = true,
      },

      runtime = {
        builtin           = nil, -- default
        fileEncoding      = "utf8",
        meta              = "${version} ${language} ${encoding}",
        nonstandardSymbol = nil,
        ---@type string[]
        path              = { "?.lua", "?/init.lua" },
        pathStrict        = true,
        plugin            = nil,
        pluginArgs        = nil,
        special = {
          ["my.std.luamod.reload"] = "require",
          ["my.std.luamod.if_exists"] = "require",
          ["busted.require"] = "require",
        },
        unicodeName       = false,
        version           = "LuaJIT",
      },

      semantic = {
        annotation = true,
        enable     = true,
        keyword    = true,
        variable   = true,
      },

      signatureHelp = {
        enable = false,
      },

      spell = {
        dict = nil,
      },

      type = {
        castNumberToInteger = true,
        checkTableShape     = false,
        weakNilCheck        = true,
        weakUnionCheck      = true,
        inferParamType      = false,
      },

      window = {
        progressBar = false,
        statusBar   = false,
      },

      workspace = {
        checkThirdParty  = Disable,
        ---@type string[]
        ignoreDir        = {
          "ldoc/builtin",
        },
        ignoreSubmodules = true,
        ---@type string[]
        library          = {},
        maxPreload       = nil,
        preloadFileSize  = nil,
        useGitIgnore     = true,
        userThirdParty   = {},
      },
    },
  },
}

do
  local diag = defaults.settings.Lua.diagnostics

  -- explicitly disable diagnostics set to `None`
  -- idk if this has any real effect
  diag.disable = {}
  for name, val in pairs(diag.neededFileStatus) do
    if val == None then
      insert(diag.disable, name)
    end
  end
end

return defaults

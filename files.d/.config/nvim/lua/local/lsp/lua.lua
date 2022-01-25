local fs = require 'local.fs'
local mod = require 'local.module'

local stdpath = vim.fn.stdpath
local expand = vim.fn.expand
local split = vim.fn.split
local endswith   = vim.endswith
local insert = table.insert

local EMPTY = {}

local USER_SETTINGS = expand('~/.config/lua/lua-lsp.json')

---@alias local.lsp.filenames string[]

---@class local.lsp.settings
---@field include_vim boolean
---@field third_party? local.lsp.filenames
local DEFAULT_SETTINGS = {

  -- Make the server aware of Neovim runtime files
  include_vim = false,

  ---@class local.lsp.settings.lib : table
  ---@field extra?      local.lsp.filenames
  lib = {
    extra = {},
  },

  ---@class local.lsp.settings.path : table
  ---@field extra? local.lsp.filenames
  path = {
    extra = {},
  },

  third_party = nil,
}

---@param p string
---@return local.lsp.filenames
local function expand_paths(p)
  p = expand(p)
  p = split(p, "\n", false)
  return p
end

---@return local.lsp.filenames
local function packer_dirs()
  local dirs = {}
  mod.if_exists('packer', function()
    local glob = stdpath('data') .. '/site/pack/packer/*/*/lua'
    for _, dir in ipairs(expand_paths(glob)) do
      insert(dirs, dir)
    end
  end)
  return dirs
end

---@param t table
---@param extra table?
---@return table
local function merge(t, extra)
  if type(t) == 'table' and type(extra) == 'table' then
    for k, v in pairs(extra) do
      t[k] = merge(t[k], v)
    end
    return t
  end

  return extra
end

---@return local.lsp.settings
local function load_user_settings()
  local settings = DEFAULT_SETTINGS

  local user = fs.read_json_file(USER_SETTINGS)
  merge(settings, user)

  local root = fs.workspace_root()
  if root then
    local workspace = fs.read_json_file(root .. "/.lua-lsp.json")
    merge(settings, workspace)
  end

  return settings
end

---@param settings local.lsp.settings
local function lua_libs(settings)
  local libs = {}

  if settings.include_vim then
    libs[expand('$VIMRUNTIME/lua')] = true

    for _, dir in ipairs(packer_dirs()) do
      libs[dir] = true
    end
  end

  for _, item in ipairs(settings.lib.extra or EMPTY) do
    for _, elem in ipairs(expand_paths(item)) do
      libs[elem] = true
    end
  end

  libs[expand("$PWD")] = true

  local ws = fs.workspace_root()
  if ws then
    libs[ws] = true
  end

  return libs
end

---@param paths local.lsp.filenames
---@param dir string
local function add_lua_path(paths, dir)
  insert(paths, dir .. '/?.lua')
  insert(paths, dir .. '/?/init.lua')
end

---@param settings local.lsp.settings
---@param libs table<string, boolean>
---@return string[]
local function lua_path(settings, libs)
  local path = split(package.path, ';', false)

  -- something changed in lua-language-server 2.5.0 with regards to locating
  -- `require`-ed filenames from package.path. These no longer work:
  --
  -- * relative (`./`) references to the current working directory:
  --   * ./?.lua
  --   * ./?/init.lua
  -- * absolute references to the current working directory:
  --   * $PWD/?.lua
  --   * $PWD/?/init.lua
  --
  -- ...but `?.lua` and `?/init.lua` work, so let's use them instead
  insert(path, "?.lua")
  insert(path, "?/init.lua")

  for lib in pairs(libs) do
    -- add $path
    add_lua_path(path, lib)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(path, lib .. '/lua')
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(path, lib .. '/src')
    end
  end

  for _, extra in ipairs(settings.path.extra or EMPTY) do
    for _, elem in ipairs(expand_paths(extra)) do
      add_lua_path(path, elem)
    end
  end

  return path
end

local settings = load_user_settings()
local library = lua_libs(settings)
local path = lua_path(settings, library)

-- https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
local conf = {
  cmd = { 'lua-language-server' },
  settings = {
    Lua = {

      runtime = {
        --- runtime.fileEncoding
        --- default: utf8
        --- File encoding. The `ansi` option is only available under the `Windows` platform.
        ---@type '"utf8"'|'"ansi"'|'"utf16le"'|'"utf16be"'
        fileEncoding = "utf8",

        --- runtime.nonstandardSymbol
        --- Supports non-standard symbols. Make sure that your runtime environment supports these symbols.
        ---@type string[]
        nonstandardSymbol = {},

        --- runtime.path
        --- When using `require`, how to find the file based on the input name.
        --- Setting this config to `?/init.lua` means that when you enter `require 'myfile'`, `${workspace}/myfile/init.lua` will be searched from the loaded files.
        --- if `runtime.pathStrict` is `false`, `${workspace}/**/myfile/init.lua` will also be searched.
        --- If you want to load files outside the workspace, you need to set `Lua.workspace.library` first.
        ---@type string[]
        path = path,

        --- runtime.pathStrict
        --- When enabled, `runtime.path` will only search the first level of directories, see the description of `runtime.path`.
        ---@type boolean
        pathStrict = false,

        --- runtime.plugin
        --- default:
        --- Plugin path. Please read [wiki](https://github.com/sumneko/lua-language-server/wiki/Plugin) to learn more.
        ---@type string
        plugin = nil,

        --- runtime.unicodeName
        --- Allows Unicode characters in name.
        ---@type boolean
        unicodeName = true,

        --- runtime.version
        --- default: Lua 5.4
        --- Lua runtime version.
        ---@type '"Lua 5.1"'|'"Lua 5.2"'|'"Lua 5.3"'|'"Lua 5.4"'|'"LuaJIT"'
        version = 'LuaJIT', -- neovim implies luajit

        ---@alias runtime.builtin.state
        ---| '"default"' # Indicates that the library will be enabled or disabled according to the runtime version
        ---| '"enable"'  # Always enabled
        ---| '"disable"' # Always disabled

        --- runtime.builtin
        --- Adjust the enabled state of the built-in library. You can disable (or redefine) the non-existent library according to the actual runtime environment.
        --- @class runtime.builtin
        ---
        ---@field basic     runtime.builtin.state
        ---@field bit       runtime.builtin.state
        ---@field bit32     runtime.builtin.state
        ---@field builtin   runtime.builtin.state
        ---@field coroutine runtime.builtin.state
        ---@field debug     runtime.builtin.state
        ---@field ffi       runtime.builtin.state
        ---@field io        runtime.builtin.state
        ---@field jit       runtime.builtin.state
        ---@field math      runtime.builtin.state
        ---@field os        runtime.builtin.state
        ---@field package   runtime.builtin.state
        ---@field string    runtime.builtin.state
        ---@field table     runtime.builtin.state
        ---@field utf8      runtime.builtin.state
        builtin = nil,

        ---@alias runtime.special.variable
        ---| '"_G"'
        ---| '"rawset"'
        ---| '"rawget"'
        ---| '"setmetatable"'
        ---| '"require"'
        ---| '"dofile"'
        ---| '"loadfile"'
        ---| '"pcall"'
        ---| '"xpcall"'

        --- runtime.special
        --- The custom global variables are regarded as some special built-in variables, and the language server will provide special support
        --- The following example shows that 'include' is treated as' require '.
        --- ```lua
        --- {
        ---   runtime = {
        ---     special = {
        ---       include = "require",
        ---     },
        ---   },
        --- }
        --- ```
        ---@type table<string, runtime.special.variable>
        special = nil,

      },

      completion = {
        enable = true,

        --- completion.autoRequire
        --- default: true
        --- When the input looks like a file name, automatically `require` this file.
        ---@type boolean
        autoRequire = true,

        --- completion.callSnippet
        --- default: Disable
        --- Shows function call snippets.
        ---@type
        ---| '"Disable"' # Only shows `function name`.
        ---| '"Both"' # Shows `function name` and `call snippet`.
        ---| '"Replace"' # Only shows `call snippet.`
        callSnippet = "Disable",

        --- completion.displayContext
        --- default: 0
        --- Previewing the relevant code snippet of the suggestion may help you understand the usage of the suggestion. The number set indicates the number of intercepted lines in the code fragment. If it is set to `0`, this feature can be disabled.
        ---@type integer
        displayContext = 0,


        --- completion.keywordSnippet
        --- default: Replace
        --- Shows keyword syntax snippets.
        ---@type
        ---| '"Disable"' # Only shows `keyword`.
        ---| '"Both"' # Shows `keyword` and `syntax snippet`.
        ---| '"Replace"' # Only shows `syntax snippet`.
        keywordSnippet = "Replace",

        --- completion.postfix
        --- default: @
        --- The symbol used to trigger the postfix suggestion.
        ---@type string
        postfix = "@",

        --- completion.requireSeparator
        --- default: .
        --- The separator used when `require`.
        ---@type string
        requireSeparator = ".",

        --- completion.showParams
        --- default: true
        --- Display parameters in completion list. When the function has multiple definitions, they will be displayed separately.
        ---@type boolean
        showParams = true,

        --- completion.showWord
        --- default: Fallback
        --- Show contextual words in suggestions.
        ---@type
        ---| '"Enable"' # Always show context words in suggestions.
        ---| '"Fallback"' # Contextual words are only displayed when suggestions based on semantics cannot be provided.
        ---| '"Disable"' # Do not display context words.
        showWord = "Fallback",

        --- completion.workspaceWord
        --- default: true
        --- Whether the displayed context word contains the content of other files in the workspace.
        ---@type boolean
        workspaceWord = true,

      },

      signatureHelp = {
        enable = true,
      },

      hover = {
        enable = true,

        --- hover.enumsLimit
        --- default: 5
        --- When the value corresponds to multiple types, limit the number of types displaying.
        ---@type integer
        enumsLimit = 5,

        --- hover.previewFields
        --- default: 20
        --- When hovering to view a table, limits the maximum number of previews for fields.
        ---@type integer
        previewFields = 20,

        --- hover.viewNumber
        --- default: true
        --- Hover to view numeric content (only if literal is not decimal).
        ---@type boolean
        viewNumber = true,

        --- hover.viewString
        --- default: true
        --- Hover to view the contents of a string (only if the literal contains an escape character).
        ---@type boolean
        viewString = true,

        --- hover.viewStringMax
        --- default: 1000
        --- The maximum length of a hover to view the contents of a string.
        ---@type integer
        viewStringMax = 1000,

      },

      hint = {
        enable = true,

        --- hint.paramName
        --- default: All
        --- Show hints of parameter name at the function call.
        ---@type
        ---| '"All"' # All types of parameters are shown.
        ---| '"Literal"' # Only literal type parameters are shown.
        ---| '"Disable"' # Disable parameter hints.
        paramName = "All",

        --- hint.paramType
        --- default: true
        --- Show type hints at the parameter of the function.
        ---@type boolean
        paramType = true,

        --- hint.setType
        --- Show hints of type at assignment operation.
        ---@type boolean
        setType = true,

      },

      -- intellisense settings.
      --
      -- These things are a little expensive, but they help a lot.
      --
      -- https://github.com/sumneko/lua-language-server/wiki/IntelliSense-optional-features
      IntelliSense = {
        -- https://github.com/sumneko/lua-language-server/issues/872
        traceLocalSet    = true,
        traceReturn      = true,
        traceBeSetted    = true,
        traceFieldInject = true,
      },

      diagnostics = {
        --- diagnostics.enable
        --- default: true
        --- Enable diagnostics.
        ---@type boolean
        enable = true,

        --- diagnostics.disable
        --- Disabled diagnostic (Use code in hover brackets).
        ---@type string[]
        disable = {
          'lowercase-global',
        },

        --- diagnostics.globals
        --- Defined global variables.
        ---@type string[]
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

        --- diagnostics.ignoredFiles
        --- default: Opened
        --- How to diagnose ignored files.
        ---@type
        ---| '"Enable"' # Always diagnose these files.
        ---| '"Opened"' # Only when these files are opened will it be diagnosed.
        ---| '"Disable"' # These files are not diagnosed.
        ignoredFiles = "Opened",

        --- diagnostics.libraryFiles
        --- default: Opened
        --- How to diagnose files loaded via `Lua.workspace.library`.
        ---@type
        ---| '"Enable"' # Always diagnose these files.
        ---| '"Opened"' # Only when these files are opened will it be diagnosed.
        ---| '"Disable"' # These files are not diagnosed.
        libraryFiles = "Opened",

        --- diagnostics.workspaceDelay
        --- default: 3000
        --- Latency (milliseconds) for workspace diagnostics. When you start the workspace, or edit any file, the entire workspace will be re-diagnosed in the background. Set to negative to disable workspace diagnostics.
        ---@type integer
        workspaceDelay = 3000,

        --- diagnostics.workspaceRate
        --- default: 100
        --- Workspace diagnostics run rate (%). Decreasing this value reduces CPU usage, but also reduces the speed of workspace diagnostics. The diagnosis of the file you are currently editing is always done at full speed and is not affected by this setting.
        ---@type integer
        workspaceRate = 80,

        ---@alias diagnostics.neededFileStatus.Status '"Any"'|'"Opened"'|'"None"'

        --- diagnostics.neededFileStatus
        --- If you want to check only opened files, choice Opened; else choice Any.
        ---@class diagnostics.neededFileStatus
        ---
        ---@field ambiguity-1            diagnostics.neededFileStatus.Status
        ---@field await-in-sync          diagnostics.neededFileStatus.Status
        ---@field circle-doc-class       diagnostics.neededFileStatus.Status
        ---@field close-non-object       diagnostics.neededFileStatus.Status
        ---@field code-after-break       diagnostics.neededFileStatus.Status
        ---@field count-down-loop        diagnostics.neededFileStatus.Status
        ---@field deprecated             diagnostics.neededFileStatus.Status
        ---@field different-requires     diagnostics.neededFileStatus.Status
        ---@field discard-returns        diagnostics.neededFileStatus.Status
        ---@field doc-field-no-class     diagnostics.neededFileStatus.Status
        ---@field duplicate-doc-class    diagnostics.neededFileStatus.Status
        ---@field duplicate-doc-field    diagnostics.neededFileStatus.Status
        ---@field duplicate-doc-param    diagnostics.neededFileStatus.Status
        ---@field duplicate-index        diagnostics.neededFileStatus.Status
        ---@field duplicate-set-field    diagnostics.neededFileStatus.Status
        ---@field empty-block            diagnostics.neededFileStatus.Status
        ---@field global-in-nil-env      diagnostics.neededFileStatus.Status
        ---@field lowercase-global       diagnostics.neededFileStatus.Status
        ---@field newfield-call          diagnostics.neededFileStatus.Status
        ---@field newline-call           diagnostics.neededFileStatus.Status
        ---@field no-implicit-any        diagnostics.neededFileStatus.Status
        ---@field not-yieldable          diagnostics.neededFileStatus.Status
        ---@field redefined-local        diagnostics.neededFileStatus.Status
        ---@field redundant-parameter    diagnostics.neededFileStatus.Status
        ---@field redundant-return       diagnostics.neededFileStatus.Status
        ---@field redundant-value        diagnostics.neededFileStatus.Status
        ---@field trailing-space         diagnostics.neededFileStatus.Status
        ---@field type-check             diagnostics.neededFileStatus.Status
        ---@field unbalanced-assignments diagnostics.neededFileStatus.Status
        ---@field undefined-doc-class    diagnostics.neededFileStatus.Status
        ---@field undefined-doc-name     diagnostics.neededFileStatus.Status
        ---@field undefined-doc-param    diagnostics.neededFileStatus.Status
        ---@field undefined-env-child    diagnostics.neededFileStatus.Status
        ---@field undefined-field        diagnostics.neededFileStatus.Status
        ---@field undefined-global       diagnostics.neededFileStatus.Status
        ---@field unknown-diag-code      diagnostics.neededFileStatus.Status
        ---@field unused-function        diagnostics.neededFileStatus.Status
        ---@field unused-label           diagnostics.neededFileStatus.Status
        ---@field unused-local           diagnostics.neededFileStatus.Status
        ---@field unused-vararg          diagnostics.neededFileStatus.Status
        neededFileStatus = nil,

        ---@alias diagnostics.severity.Level
        ---| '"Hint"'
        ---| '"Information"'
        ---| '"Warning"'
        ---| '"Error"'

        --- diagnostics.severity
        --- Modified diagnostic severity.
        ---@class diagnostics.severity
        ---
        ---@field ambiguity-1            diagnostics.severity.Level
        ---@field await-in-sync          diagnostics.severity.Level
        ---@field circle-doc-class       diagnostics.severity.Level
        ---@field close-non-object       diagnostics.severity.Level
        ---@field code-after-break       diagnostics.severity.Level
        ---@field count-down-loop        diagnostics.severity.Level
        ---@field deprecated             diagnostics.severity.Level
        ---@field different-requires     diagnostics.severity.Level
        ---@field discard-returns        diagnostics.severity.Level
        ---@field doc-field-no-class     diagnostics.severity.Level
        ---@field duplicate-doc-class    diagnostics.severity.Level
        ---@field duplicate-doc-field    diagnostics.severity.Level
        ---@field duplicate-doc-param    diagnostics.severity.Level
        ---@field duplicate-index        diagnostics.severity.Level
        ---@field duplicate-set-field    diagnostics.severity.Level
        ---@field empty-block            diagnostics.severity.Level
        ---@field global-in-nil-env      diagnostics.severity.Level
        ---@field lowercase-global       diagnostics.severity.Level
        ---@field newfield-call          diagnostics.severity.Level
        ---@field newline-call           diagnostics.severity.Level
        ---@field no-implicit-any        diagnostics.severity.Level
        ---@field not-yieldable          diagnostics.severity.Level
        ---@field redefined-local        diagnostics.severity.Level
        ---@field redundant-parameter    diagnostics.severity.Level
        ---@field redundant-return       diagnostics.severity.Level
        ---@field redundant-value        diagnostics.severity.Level
        ---@field trailing-space         diagnostics.severity.Level
        ---@field type-check             diagnostics.severity.Level
        ---@field unbalanced-assignments diagnostics.severity.Level
        ---@field undefined-doc-class    diagnostics.severity.Level
        ---@field undefined-doc-name     diagnostics.severity.Level
        ---@field undefined-doc-param    diagnostics.severity.Level
        ---@field undefined-env-child    diagnostics.severity.Level
        ---@field undefined-field        diagnostics.severity.Level
        ---@field undefined-global       diagnostics.severity.Level
        ---@field unknown-diag-code      diagnostics.severity.Level
        ---@field unused-function        diagnostics.severity.Level
        ---@field unused-label           diagnostics.severity.Level
        ---@field unused-local           diagnostics.severity.Level
        ---@field unused-vararg          diagnostics.severity.Level
        severity = nil,

      },

      workspace = {

        --- workspace.checkThirdParty
        --- default: true
        --- Automatic detection and adaptation of third-party libraries, currently supported libraries are:
        --- * OpenResty
        --- * Cocos4.0
        --- * LÖVE
        --- * skynet
        --- * Jass
        ---@type boolean
        checkThirdParty = false,

        --- workspace.ignoreDir
        --- default: ?
        --- Ignored files and directories (Use `.gitignore` grammar).
        ---@type string[]
        ignoreDir = nil,

        --- workspace.ignoreSubmodules
        --- default: true
        --- Ignore submodules.
        ---@type boolean
        ignoreSubmodules = false,

        --- workspace.library
        --- In addition to the current workspace, which directories will load files from. The files in these directories will be treated as externally provided code libraries, and some features (such as renaming fields) will not modify these files.
        ---@type string[]
        library = library,

        --- workspace.maxPreload
        --- default: 5000
        --- Max preloaded files.
        ---@type integer
        maxPreload = nil,

        --- workspace.preloadFileSize
        --- default: 500
        --- Skip files larger than this value (KB) when preloading.
        ---@type integer
        preloadFileSize = nil,

        --- workspace.useGitIgnore
        --- default: true
        --- Ignore files list in `.gitignore` .
        ---@type boolean
        useGitIgnore = nil,

        --- workspace.userThirdParty
        --- Add private third-party library configuration file paths here, please refer to the built-in [configuration file path](https://github.com/sumneko/lua-language-server/tree/master/meta/3rd)
        ---@type string[]
        userThirdParty = settings.third_party,

      },

      telemetry = {
        --- telemetry.enable
        --- default: userdata: (nil)
        --- Enable telemetry to send your editor information and error logs over the network. Read our privacy policy [here](https://github.com/sumneko/lua-language-server/wiki/Privacy-Policy).
        ---@type boolean
        enable = false,
      },
    },
  }
}

if settings.include_vim then
 mod.if_exists("lua-dev", function(luadev)
   conf = luadev.setup({ lspconfig = conf })
 end)
end
return conf

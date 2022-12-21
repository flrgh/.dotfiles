if require("local.config.globals").bootstrap then
  return
end

local fs = require 'local.fs'
local mod = require 'local.module'
local globals = require "local.config.globals"

local expand = vim.fn.expand
local endswith   = vim.endswith
local insert = table.insert
local runtime_paths = vim.api.nvim_list_runtime_paths
local dir_exists = fs.dir_exists
local find = string.find
local runtime_file = vim.api.nvim_get_runtime_file

local WORKSPACE = fs.normalize(require("local.config.globals").workspace)

local LUA_PATH = os.getenv("LUA_PATH") or package.path

local EMPTY = {}

---@type string
local USER_SETTINGS = expand("~/.config/lua/lsp.lua", nil, false)

---@type string
local ANNOTATIONS = globals.git_user_root .. "/lua-type-annotations"

---@type string
local SUMNEKO = expand("~/.local/libexec/lua-language-server/meta/3rd", nil, false)

local NVIM_LUA = globals.dotfiles.config_nvim_lua

local get_plugin_dir
do
  local cache = {}
  ---@param name string
  ---@return string|nil
  function get_plugin_dir(name)
    local dir = cache[name]
    if dir then return dir end

    local len = name:len()
    for _, p in ipairs(runtime_file("", true)) do
      if p:sub(-len) == name then
        cache[name] = p
        return p
      end
    end
  end
end

local function get_plugin_lua_dir(name)
  local dir = get_plugin_dir(name)
  if dir then
    return dir .. "/lua"
  end
end


---@class local.lsp.settings
---@field include_vim boolean
---@field third_party string[]
---@field ignore string[]
---@field paths string[]
---@field libraries string[]
local DEFAULT_SETTINGS = {
  -- Make the server aware of Neovim runtime files
  include_vim = false,

  libraries = {},
  paths = {},
  third_party = {},
  ignore = {},
}

---@param p string
---@return string
local function normalize(p, skip_realpath)
  if skip_realpath then
    return fs.normalize(p)
  else
    return fs.realpath(p)
  end
end

---@param p string
---@return string[]
local function expand_paths(p)
  p = p:gsub("$TYPES", ANNOTATIONS)

  if p:find("$SUMNEKO", nil, true) then
    p = p:gsub("$SUMNEKO", SUMNEKO)
    p = p .. "/library"
  end

  p = p:gsub("$DOTFILES_CONFIG_NVIM_LUA", NVIM_LUA)


  return expand(p, nil, true)
end

local _runtime_dirs

---@return string[]
local function runtime_lua_dirs()
  if _runtime_dirs then return _runtime_dirs end
  _runtime_dirs = {}

  for _, dir in ipairs(runtime_paths()) do
    if dir_exists(dir .. "/lua") then
      insert(_runtime_dirs, dir .. "/lua")
    end
  end

  return _runtime_dirs
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

local function append(a, b)
  if type(b) == "table" then
    for _, v in ipairs(b) do
      insert(a, v)
    end
  else
    insert(a, b)
  end
end

---@param a table
---@param b table
---@return table|nil
local function imerge(a, b)
  if not b then return end
  local seen = {}

  for _, v in ipairs(a) do
    seen[v] = true
  end

  for _, v in ipairs(b) do
    if not seen[v] then
      seen[v] = true
      insert(a, v)
    end
  end

  return a
end

---@param paths string[]
---@return string[]
local function dedupe(paths, skip_realpath)
  local seen = {}
  local new = {}
  local i = 0
  for _, p in ipairs(paths) do
    p = normalize(p, skip_realpath)
    if not seen[p] then
      seen[p] = true
      i = i + 1
      new[i] = p
    end
  end
  return new
end


---@return local.lsp.settings
local function load_user_settings()
  local settings = DEFAULT_SETTINGS

  local user
  if fs.file_exists(USER_SETTINGS) then
    user = dofile(USER_SETTINGS)
  end

  local base = fs.basename(WORKSPACE)

  for ws, conf in pairs(user.workspaces or {}) do
    if ws == base or
       ws == "*" or
       find(base, ws, nil, true)
    then
      imerge(settings.libraries, conf.libraries)
      imerge(settings.paths, conf.paths)
      imerge(settings.ignore, conf.ignore)
      if conf.include_vim then
        settings.include_vim = true
      end
    end
  end

  if base == ".dotfiles" or base == "dotfiles" then
    settings.include_vim = true
  end

  return settings
end

local plugin_libs = {
  "nvim-cmp",
  "packer.nvim",
  "neodev.nvim",
}

---@param settings local.lsp.settings
local function lua_libs(settings)
  local libs = {}

  for _, item in ipairs(settings.libraries or EMPTY) do
    for _, elem in ipairs(expand_paths(item)) do
      elem = fs.normalize(elem)
      if elem ~= WORKSPACE then
        insert(libs, elem)
      end
    end
  end

  if settings.include_vim then
    if mod.exists("neodev.sumneko") then
      local sumneko = require "neodev.sumneko"

      if type(sumneko.library) == "function" then
        append(libs, sumneko.library({
          library = {
            types = true,
          }
        }))

      else
        vim.notify("function `neodev.sumneko.library()` is missing")
      end

    else
      vim.notify("module `neodev.sumneko` is missing")
    end

    if ANNOTATIONS and dir_exists(ANNOTATIONS) then
      insert(libs, ANNOTATIONS .. "/luv")
      insert(libs, ANNOTATIONS .. "/neovim")
    end

    for _, name in ipairs(plugin_libs) do
      local lib = get_plugin_lua_dir(name)
      if lib then
        insert(libs, lib)
      end
    end
  end

  return dedupe(libs)
end

---@param paths string[]
---@param dir string
local function add_lua_path(paths, dir)
  if dir then
    insert(paths, dir .. '/?.lua')
    insert(paths, dir .. '/?/init.lua')
  end
end

---@param settings local.lsp.settings
---@param libs table<string, boolean>
---@return string[]
local function lua_path(settings, libs)
  local paths = {}

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
  insert(paths, "?.lua")
  insert(paths, "?/init.lua")

  for _, extra in ipairs(settings.paths or EMPTY) do
    for _, elem in ipairs(expand_paths(extra)) do
      add_lua_path(paths, elem)
    end
  end

  if settings.include_vim then
    add_lua_path(paths, expand("$VIMRUNTIME/lua"))
    for _, p in ipairs(runtime_lua_dirs()) do
      add_lua_path(paths, p)
    end
  end

  for _, lib in ipairs(libs) do
    -- add $path
    add_lua_path(paths, lib)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(paths, lib .. '/lua')
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(paths, lib .. '/src')
    end

    -- add $path/lib
    if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
      add_lua_path(paths, lib .. '/lib')
    end
  end

  ---@diagnostic disable-next-line
  LUA_PATH:gsub("[^;]+", function(path)
    path = fs.normalize(path)
    local dir = path:gsub("%?%.lua$", ""):gsub("%?/init%.lua$", "")

    if path ~= "" and
       path ~= "/" and
       dir ~= WORKSPACE
    then
      insert(paths, path)
    end
  end)

  return dedupe(paths, true)
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
        ---@type "utf8"|"ansi"|"utf16le"|"utf16be"
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
        ---@type "Lua 5.1"|"Lua 5.2"|"Lua 5.3"|"Lua 5.4"|"LuaJIT"
        version = 'LuaJIT', -- neovim implies luajit

        ---@alias runtime.builtin.state
        ---| "default" # Indicates that the library will be enabled or disabled according to the runtime version
        ---| "enable"  # Always enabled
        ---| "disable" # Always disabled

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
        ---| "_G"
        ---| "rawset"
        ---| "rawget"
        ---| "setmetatable"
        ---| "require"
        ---| "dofile"
        ---| "loadfile"
        ---| "pcall"
        ---| "xpcall"

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
        special = {
          ["local.module.reload"] = "require",
          ["local.module.if_exists"] = "require",
        },

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
        ---| "Disable" # Only shows `function name`.
        ---| "Both" # Shows `function name` and `call snippet`.
        ---| "Replace" # Only shows `call snippet.`
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
        ---| "Disable" # Only shows `keyword`.
        ---| "Both" # Shows `keyword` and `syntax snippet`.
        ---| "Replace" # Only shows `syntax snippet`.
        keywordSnippet = "Replace",

        --- completion.postfix
        --- default: `@`
        --- The symbol used to trigger the postfix suggestion.
        ---@type string
        postfix = "@",

        --- completion.requireSeparator
        --- default: `.`
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
        ---| "Enable" # Always show context words in suggestions.
        ---| "Fallback" # Contextual words are only displayed when suggestions based on semantics cannot be provided.
        ---| "Disable" # Do not display context words.
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

        --- hover.expandAlias
        --- Whether to expand the alias. For example, expands ---@alias myType boolean|number appears as boolean|number, otherwise it appears as `myType'.
        ---@type boolean
        expandAlias = true,

      },

      hint = {
        enable = true,

        --- hint.paramName
        --- default: All
        --- Show hints of parameter name at the function call.
        ---@type
        ---| "All" # All types of parameters are shown.
        ---| "Literal" # Only literal type parameters are shown.
        ---| "Disable" # Disable parameter hints.
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

        --- hint.arrayIndex
        --- Show hints of array index when constructing a table.
        ---@type "Enable"|"Auto"|"Disable"
        arrayIndex = "Enable",

        --- hint.await
        --- If the called function is marked ---@async, prompt await at the call.
        ---@type boolean
        await = false,

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
          'need-check-nil',
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
        ---| "Enable" # Always diagnose these files.
        ---| "Opened" # Only when these files are opened will it be diagnosed.
        ---| "Disable" # These files are not diagnosed.
        ignoredFiles = "Opened",

        --- diagnostics.libraryFiles
        --- default: Opened
        --- How to diagnose files loaded via `Lua.workspace.library`.
        ---@type
        ---| "Enable" # Always diagnose these files.
        ---| "Opened" # Only when these files are opened will it be diagnosed.
        ---| "Disable" # These files are not diagnosed.
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

        ---@alias diagnostics.neededFileStatus.Status "Any"|"Opened"|"None"

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
        ---| "Hint"
        ---| "Information"
        ---| "Warning"
        ---| "Error"

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
        ---@type string[]?
        ignoreDir = settings.ignore,

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
        useGitIgnore = true,

        --- workspace.userThirdParty
        --- Add private third-party library configuration file paths here, please refer to the built-in [configuration file path](https://github.com/sumneko/lua-language-server/tree/master/meta/3rd)
        ---@type string[]?
        userThirdParty = settings.third_party,

      },

      semantic = {
        --- Semantic coloring of type annotations.
        --- default: true
        ---@type boolean
        annotation = true,

        --- Enable semantic color. You may need to set `editor.semanticHighlighting.enabled` to `true` to take effect.
        --- default: true
        ---@type boolean
        enable = true,

        --- Semantic coloring of keywords/literals/operators. You only need to enable this feature if your editor cannot do syntax coloring.
        --- default: false
        ---@type boolean
        keyword = nil,

        --- Semantic coloring of variables/fields/parameters.
        ---@type boolean
        variable = true,
      },

      telemetry = {
        --- telemetry.enable
        --- default: userdata: (nil)
        --- Enable telemetry to send your editor information and error logs over the network. Read our privacy policy [here](https://github.com/sumneko/lua-language-server/wiki/Privacy-Policy).
        ---@type boolean
        enable = true,
      },

      type = {
        --- castNumberToInteger
        -- Allowed to assign the number type to the integer type.
        ---@type boolean
        castNumberToInteger = true,

        --- weakUnionCheck
        --
        -- Once one subtype of a union type meets the condition, the union type also meets the condition.
        --
        -- When this setting is false, the number|boolean type cannot be assigned to the number type. It can be with true.
        ---@type boolean
        weakUnionCheck = true,
      },
    },
  }
}

return conf

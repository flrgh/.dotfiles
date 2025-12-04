local _M = {}

local env = require("my.env")

_M.NAME = "lua_ls"

_M.Ask = "Ask"
_M.ApplyInMemory = "ApplyInMemory"
_M.Apply = "Apply"
_M.Disable = "Disable"
_M.Replace = "Replace"
_M.Fallback = "Fallback"
_M.Opened = "Opened!"
_M.None = "None!"
_M.Enable = "Enable"
_M.All = "All"


_M.SRC_TYPE_DEFS = "type-definitions"
_M.SRC_RUNTIME_PATH = "Lua.runtime.path"
_M.SRC_WS_LIBRARY = "Lua.workspace.library"
_M.SRC_PLUGIN = "plugin"
_M.SRC_LUA_PATH = "$LUA_PATH / package.path"
_M.SRC_WORKSPACE_ROOT = "LSP.root_dir"
_M.SRC_LUA_BUNDLE = "nvim/_lua_bundle"


_M.LUA_TYPE_ANNOTATIONS = env.git_user_root .. "/lua-type-annotations"
_M.LUA_CATS = env.git_root .. "/LuaCATS"
_M.LUA_RESTY_COMMUNITY = env.git_user_root .. "/resty-community-typedefs"

local SERVER_DIR = env.home .. "/.local/libexec/lua-language-server"

_M.SERVER = {
  DIR = SERVER_DIR,
  EXE = SERVER_DIR .. "/bin/lua-language-server",
  META_DIR = env.nvim.state .. "/lua-lsp",
  LOG_DIR = env.home .. "/.local/var/log/lua-lsp",
  LOCALE = "en-us",
}
setmetatable(_M.SERVER, {
  __index = function(_, k)
    error("undefined config constant: SERVER." .. tostring(k))
  end,
})


setmetatable(_M, {
  __index = function(_, k)
    error("undefined config constant: " .. tostring(k))
  end,
})

return _M

-- LuaRocks configuration

rocks_trees = {
    {
        name = "user",
        root = home .. "/.local"
    },
    {
        name = "system",
        root = "/usr"
    }
}

lua_interpreter = "lua"

variables = {
   LUA_DIR = "/usr",
   LUA_BINDIR = "/usr/bin",
   LUA_LIBDIR = "/usr/lib64"
}

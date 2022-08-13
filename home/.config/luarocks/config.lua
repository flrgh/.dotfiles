-- LuaRocks configuration

rocks_trees = {
    {
        name = "user",
        root = home .. "/.local",
    },
}

lua_interpreter = "lua"

variables = {
   LUA_DIR = home .. "/.local",
   LUA_BINDIR = home .. "/.local/bin",
   LUA_LIBDIR = home .. "/.local/lib",
}

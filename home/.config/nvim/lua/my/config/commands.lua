local add_command = vim.api.nvim_create_user_command

add_command("Dump",
  "lua vim.pretty_print(<args>)",
  { nargs = 1,
    complete = "lua",
    force = true,
  }
)

add_command("LuaDebug",
  function()
    local fs = require "my.utils.fs"

    local home = os.getenv("HOME")

    local buf = require("string.buffer").new()

    ---@type { path:string, realpath:string|nil, label:string, replace:string }[]
    local replacements = {}

    ---@param subject string
    ---@param substr string
    ---@param replacement string
    ---@return string
    local function replace(subject, substr, replacement)
      if subject == "" or substr == "" then
        return subject
      end

      local from, to = subject:find(substr, nil, true)
      if from then
        return subject:sub(1, from - 1)
            .. replacement
            .. subject:sub(to + 1)
      end

      return subject
    end

    ---@param path string
    ---@param label string
    local function replace_path(path, label)
      if not path then return end

      table.insert(replacements, {
        path     = path,
        realpath = fs.realpath(path),
        label    = label,
        replace  = "{{ " .. label .. " }}",
      })

      table.sort(replacements, function(a, b)
        return a.path > b.path
      end)
    end

    ---@param path string
    ---@return string
    local function replace_common(path)
      for _, elem in ipairs(replacements) do
        path = replace(path, elem.path, elem.replace)
        if elem.realpath then
          path = replace(path, elem.realpath, elem.replace)
        end
      end

      if home then
        path = replace(path, home, "~")
      end

      return path
    end

    do
      local path = os.getenv("LUA_PATH")
      if path then
        buf:put("LUA_PATH:\n")

        ---@diagnostic disable-next-line
        path:gsub("[^;]+", function(entry)
          buf:putf("  - %s\n", entry)
        end)

      else
        buf:put("LUA_PATH: <unset>\n")
      end
    end

    buf:put("\n")

    do
      local path = os.getenv("LUA_CPATH")
      if path then
        buf:put("LUA_CPATH:\n")

        ---@diagnostic disable-next-line
        path:gsub("[^;]+", function(entry)
          buf:putf("  - %s\n", entry)
        end)

      else
        buf:put("LUA_CPATH: <unset>\n")
      end
    end

    buf:put("\n")

    do
      local init = os.getenv("LUA_INIT")
      buf:putf("LUA_INIT: %s\n", init or "<unset>")
    end

    buf:put("\n")

    ---@param name string
    ---@return string?
    local function exe(name)
      local found = vim.fn.exepath(name)
      if found and #found > 0 then
        return found
      end
    end

    ---@param cmd string[]
    ---@param env? table<string, string>
    ---@return string
    local function output(cmd, env)
      local res = vim.system(cmd, { text = true, env = env }):wait()
      if not res then
        return ""
      end

      local out = (res.stdout and res.stdout ~= "" and res.stdout)
               or (res.stderr and res.stderr ~= "" and res.stderr)

      return vim.trim(out)
    end

    local lua = exe("lua")
    if lua then
      buf:put("lua:\n")
      buf:putf("  bin: %s\n", lua)
      buf:putf("  version: %s\n", output({lua, "-v"}))

    else
      buf:put("lua: <not found>\n")
    end

    buf:put("\n")

    local luajit = exe("luajit")
    if luajit then
      buf:put("luajit:\n")
      buf:putf("  bin: %s\n", luajit)
      buf:putf("  version: %s\n", output({luajit, "-v"}))

    else
      buf:put("luajit: <not found>\n")
    end

    buf:put("\n")

    local luarocks = exe("luarocks")
    local rocks

    replace_path(vim.env.VIMRUNTIME, "nvim.runtime")
    replace_path(vim.fn.stdpath("data") .. "/lazy", "nvim.plugins")
    replace_path(require("my.config.globals").workspace, "workspace")

    if luarocks then
      buf:put("luarocks:\n")
      buf:putf("  bin: %s\n", luarocks)

      local out = output({luarocks, "config", "--json"})
      if out and out ~= "" then
        local ok
        ok, rocks = pcall(vim.json.decode, out)
        if not ok then
          buf:put("WARNING: could not parse `luarocks config --json`\n")
        end
      end

      if rocks then
        replace_path(rocks.deploy_lua_dir, "luarocks.modules")
        replace_path(rocks.variables.LUA_DIR, "luarocks.LUA_DIR")

        buf:putf("  version: %s\n", rocks.program_version)
        buf:putf("  install: %s\n", rocks.deploy_lua_dir)
        buf:putf("  LUA: %s\n", rocks.variables.LUA)
        buf:putf("  LUA_DIR: %s\n", rocks.variables.LUA_DIR)
      else
        buf:putf("  version: %s\n", output({luarocks, "--version"}))
      end

    else
      buf:put("luarocks: <not found>\n")
    end

    buf:put("\n")

    local nginx = exe("nginx")
    if nginx then
      local resty = fs.normalize(fs.dirname(nginx) .. "/../..")
      replace_path(resty, "openresty")
      buf:put("openresty:\n")
      buf:putf("  nginx: %s\n", nginx)
      buf:putf("  prefix: %s\n", resty)
    end

    buf:put("\n")

    buf:put("paths:\n")
    for _, elem in ipairs(replacements) do
      buf:putf("  %s:\n", elem.label)
      buf:putf("    path: %s\n", elem.path)

      if elem.path ~= elem.realpath then
        buf:putf("    realpath: %s\n", elem.realpath)
      end
    end

    buf:put("\n")

    do
      local client = vim.lsp.get_clients({ name = "lua_ls" })[1]
      local settings = client and client.settings and client.settings.Lua
      local function tlen(t)
        if type(t) == "table" then
          return vim.tbl_count(t)
        end
        return 0
      end

      if settings then
        buf:put("LSP:\n")

        local ws = require("my.lsp.server.lua_ls").workspace
        if ws then
          buf:put("  workspace:\n")
          if ws.dir then
            buf:putf("    dirname: %s\n", ws.dir)
          end

          if ws.path_match then
            buf:putf("    path_match: %s\n", ws.path_match)
          end

          buf:putf("    resty: %s\n", ws.settings.resty or false)
          buf:putf("    kong: %s\n", ws.settings.kong or false)
          buf:putf("    nvim: %s\n", ws.settings.nvim or false)
          buf:putf("    luarc: %s\n", ws.settings.luarc or false)
          buf:putf("    luarocks: %s\n", ws.settings.luarocks or false)
          buf:putf("    override_all: %s\n", ws.settings.override_all or false)

          buf:putf("    libraries: %s\n", tlen(ws.settings.libraries))
          buf:putf("    definitions: %s\n", tlen(ws.settings.definitions))
          buf:putf("    ignore: %s\n", tlen(ws.settings.ignore))
          buf:putf("    plugins: %s\n", tlen(ws.settings.plugins))
        end

        buf:putf("  root_dir: %s\n", client.root_dir)
        buf:putf("  runtime.version: %s\n", settings.runtime.version)

        buf:put("  runtime.path:\n")
        for _, entry in ipairs(settings.runtime.path or {}) do
          entry = replace_common(entry)
          buf:putf("    - %s\n", entry)
        end

        buf:put("  workspace.library:\n")
        for _, entry in ipairs(settings.workspace.library or {}) do
          entry = replace_common(entry)
          buf:putf("    - %s\n", entry)
        end
      end
    end

    buf:put("\n")
    vim.print(buf:get())
  end,
  {
    desc = "Show Lua/editor debug information",
  }
)

add_command("ShowEditorSettings",
  function()
    local o = vim.opt_local
    local get_info = vim.api.nvim_get_option_info2
    local opts = { scope = "local" }

    local scripts = vim.fn.getscriptinfo()
    do
      for i, s in ipairs(scripts) do
        assert(i == s.sid)
      end
    end

    local index = {
      file = {
        "filetype",
        "fileencoding",
        "fileformat",
        "bomb",
      },

      indent = {
        "autoindent",
        "tabstop",
        "softtabstop",
        "shiftwidth",
        "expandtab",
        "indentexpr",
        "indentkeys",
      },

      wrap = {
        "textwidth",
        "wrap",
        "wrapmargin",
        "wrapscan",
      },

      format = {
        "formatexpr",
        "formatoptions",
        "formatprg",
        "formatlistpat",
      },

      comment = {
        "comments",
        "commentstring",
      },

      "iskeyword",
    }

    ---@param name string
    local function summarize(name)
      local value = o[name]:get()

      local meta = get_info(name, opts)
      if not meta.was_set then
        return value
      end

      local out = {
        value = value,
        default = meta.default,
        set_by = meta.last_set_sid
                 and scripts[meta.last_set_sid]
                 and scripts[meta.last_set_sid].name,
      }

      return out
    end

    local function get(t)
      local out = {}

      for k, v in pairs(t) do
        if type(v) == "table" then
          out[k] = get(v)

        else
          out[v] = summarize(v)
        end
      end

      return out
    end

    vim.print(get(index))
  end,
  {
    desc = "Show common editor settings (indent, format, etc)",
  }
)

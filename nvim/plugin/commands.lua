if not require("my.env").editor then
  return
end

if vim.g.loaded_my_commands then
  return
end
vim.g.loaded_my_commands = true

local command = vim.api.nvim_create_user_command

local vim = vim
local lsp = vim.lsp


command("Dump",
  "lua vim.print(vim.inspect(<args>))",
  { nargs = 1,
    complete = "lua",
    force = true,
  }
)

command("LuaDebug",
  function()
    local fs = require "my.std.fs"

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
      local WS = require("my.env").workspace
      buf:put(   "my.env.workspace:\n")
      buf:putf(  "  dir: %s\n", WS.dir)
      buf:putf(  "  basename: %s\n", WS.basename)
      buf:putf(  "  meta:\n")
      for k, v in pairs(WS.meta or {}) do
        if type(v) == "table" then
          buf:putf("    %s:\n", k)
          for kk, vv in pairs(v) do
            buf:putf("      %s: %s\n", kk, vv)
          end
        else
          buf:putf("    %s: %s\n", k, v)
        end
      end
      buf:put("\n")
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

      return vim.trim(res.stdout or ""), vim.trim(res.stderr or "")
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
    replace_path(require("my.env").workspace.dir, "workspace")
    replace_path(require("my.env").nvim.bundle.root, "nvim.bundle")

    if luarocks then
      buf:put("luarocks:\n")
      buf:putf("  bin: %s\n", luarocks)

      local out = output({luarocks, "config", "--json"})
      if out and out ~= "" then
        local ok
        ok, rocks = pcall(vim.json.decode, out)
        if not ok then
          buf:put("WARNING: could not parse `luarocks config --json`\n")
          rocks = nil

        elseif type(rocks) ~= "table" then
          buf:put("WARNING: `luarocks config --json` returned a non-table\n")
          rocks = nil
        end
      end

      if rocks then
        rocks.variables = rocks.variables or {}
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

    local resty = exe("openresty")
    if resty then
      local _, stderr = output({resty, "-V"})
      local prefix

      if stderr then
        prefix = stderr:gsub(".*prefix=([^%s]+) .*", "%1")
      end

      local nginx = prefix .. "/sbin/nginx"

      if prefix then
        replace_path(prefix, "openresty")
        buf:put("openresty:\n")
        buf:putf("  prefix: %s\n", prefix)

        if fs.exists(nginx) then
          buf:putf("  nginx: %s\n", nginx)
        else
          buf:putf("  nginx: [not found]s\n")
        end
      end
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
      if settings then
        buf:put("LSP:\n")

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

        buf:put("  workspace.library.checkThirdParty: ",
                settings.workspace.checkThirdParty, "\n")

        buf:put("  workspace.library.userThirdParty:\n")
        for _, entry in ipairs(settings.workspace.userThirdParty or {}) do
          entry = replace_common(entry)
          buf:putf("    - %s\n", entry)
        end
      end
    end

    do
      local requires = require("my.std.luamod.requires")
      local r = requires.get_module_requires(0)
      buf:put("lua modules imported by this buffer:\n")
      if r then
        for _, name in ipairs(r) do
          buf:putf("  - %s\n", name)
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

command("ShowEditorSettings",
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

      patterns = {
        "iskeyword",
        "isident",
        "isfname",
        "isprint",
      },
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

command("LspSettings",
  function(args)
    ---@param client vim.lsp.Client
    local function info(client)
      return {
        name = client.name,
        settings = client.settings or vim.NIL,
        workspace_folders = client.workspace_folders or vim.NIL,
      }
    end

    if args.fargs and #args.fargs == 1 then
      local name = args.fargs[1]

      for _, client in ipairs(lsp.get_clients()) do
        if client.name == name then
          vim.print(info(client).settings)
          return
        end
      end

      vim.notify("LSP client '" .. name .. "' not found")
      return
    end

    local result = {}
    for i, client in ipairs(lsp.get_clients()) do
      result[i] = info(client)
    end

    if #result > 1 then
      vim.print(result)

    elseif #result == 1 then
      vim.print(result[1])

    else
      vim.notify("No active LSP clients")
    end
  end,
  {
    desc = "Show settings for active LSP clients",
    nargs = "?",
    complete = function()
      local names = {}
      for i, client in ipairs(lsp.get_clients()) do
        names[i] = client.name
      end
      return names
    end,
  }
)

command("LspCapabilities",
  function(args)
    ---@param client vim.lsp.Client
    local function get_caps(client)
      return {
        name = client.name,
        client = client.capabilities,
        server = client.server_capabilities,
      }
    end

    local buf = require("string.buffer").new()

    ---@param t table|any
    ---@param label string
    ---@param lvl? integer
    local function display(t, label, lvl)
      local typ = type(t)
      lvl = lvl or 0
      if typ == "table" then
        display("...", label, lvl)
        for k, v in pairs(t) do
          display(v, tostring(k), lvl + 1)
        end

      else
        buf:putf("%s%s => %q\n", string.rep("  ", lvl), label, t)
      end
    end

    local function render(info)
      buf:putf("%s\n", info.name)
      display(info.client, "client")
      display(info.server, "server")
    end

    if args.fargs and #args.fargs == 1 then
      local name = args.fargs[1]

      for _, client in ipairs(lsp.get_clients()) do
        if client.name == name then
          render(get_caps(client))
          vim.print(buf:get())
          return
        end
      end

      vim.notify("LSP client '" .. name .. "' not found")
      return
    end

    local result = {}
    for i, client in ipairs(lsp.get_clients()) do
      result[i] = get_caps(client)
    end

    if #result > 1 then
      for _, info in ipairs(result) do
        render(info)
      end
      vim.print(buf:get())

    elseif #result == 1 then
      render(result[1])
      vim.print(buf:get())

    else
      vim.notify("No active LSP clients")
    end
  end,
  {
    desc = "Show capabilities for active LSP clients",
    nargs = "?",
    complete = function()
      local names = {}
      for i, client in ipairs(lsp.get_clients()) do
        names[i] = client.name
      end
      return names
    end,
  }
)

command("UVDebug",
  function()
    local stats = require("my.state").global.uv_handle_stats
    if not stats then
      return
    end

    ---@param counts table<string, integer>
    ---@return fun():(string, integer)
    local function sorted_counts(counts)
      local keys = {}
      for k in pairs(counts) do
        table.insert(keys, k)
      end

      table.sort(keys, function(a, b)
        return counts[a] > counts[b]
      end)

      local i = 0
      return function()
        i = i + 1
        local key = keys[i]
        if key then
          return key, counts[key]
        else
          return nil
        end
      end
    end

    ---@type uv.uv_handle_t[]
    local handles = {}
    local counts = {}
    local plugin_counts = {}

    local handle_stats = stats.handles

    vim.uv.walk(function(handle)
      local type = handle:get_type()
      counts[type] = (counts[type] or 0) + 1

      local data = handle_stats[handle]
      if data and data.plugin then
        plugin_counts[data.plugin] = (plugin_counts[data.plugin] or 0) + 1
      end

      table.insert(handles, handle)
    end)

    local buf = require("string.buffer").new()
    local sep = string.rep("-", 120) .. "\n"

    if next(counts) then
      buf:put("handle counts (active):\n")
      buf:put("\n")
      for name, count in sorted_counts(counts) do
        buf:putf("%10s => %4d\n", name, count)
      end

      buf:put(sep)
    end

    if next(stats.counts.handle_type) then
      buf:put("handle counts (total):\n")
      buf:put("\n")
      for name, count in sorted_counts(stats.counts.handle_type) do
        buf:putf("%10s => %4d\n", name, count)
      end

      buf:put(sep)
    end

    if next(plugin_counts) then
      buf:put("handle counts by plugin (active):\n")
      buf:put("\n")
      for plugin, count in sorted_counts(plugin_counts) do
        buf:putf("%24s => %4d\n", plugin, count)
      end
      buf:put(sep)
    end

    if next(stats.counts.plugin) then
      buf:put("handle counts by plugin (total):\n")
      buf:put("\n")
      for plugin, count in sorted_counts(stats.counts.plugin) do
        buf:putf("%24s    %10s => %4d\n", plugin, "(total)", count)

        for htype, hcount in sorted_counts(stats.counts.plugin_handle_type[plugin]) do
          buf:putf("%24s    %10s => %4d\n", "", htype, hcount)
        end
      end
      buf:put(sep)
    end


    table.sort(handles, function(a, b)
      local ta = handle_stats[a] and handle_stats[a].serial or 0
      local tb = handle_stats[b] and handle_stats[b].serial or 0
      if ta ~= tb then
        return ta < tb
      end

      if a:get_type() ~= b:get_type() then
        return a:get_type() < b:get_type()
      end

      return tostring(a) < tostring(b)
    end)

    vim.uv.update_time()
    local now = vim.uv.now()
    local START = stats.start_time

    local SEC = 1000
    local MIN = SEC * 60
    local HR = MIN * 60
    local DAY = HR * 24
    local floor = math.floor

    local TSEP = ""

    ---@param t number
    local function put_time(t)
      if t < MIN then
        if t > 0 or TSEP == "" then
          buf:putf("%s%s seconds", TSEP, t / SEC)
        end
        TSEP = ""
        return
      end

      if t < HR then
        buf:putf("%s%d minutes", TSEP, floor(t / MIN))
        TSEP = ", "
        return put_time(t % MIN)
      end

      if t < DAY then
        buf:putf("%s%d hours", TSEP, floor(t / HR))
        TSEP = ", "
        return put_time(t % HR)
      end

      buf:putf("%d days", floor(t / DAY))
      TSEP = ", "
      return put_time(t % DAY)
    end

    for _, handle in ipairs(handles) do
      buf:putf("%s\n\n", tostring(handle))

      buf:putf("active:    %s\n", handle:is_active())
      buf:putf("closing:   %s\n", handle:is_closing())
      buf:putf("ref:       %s\n", handle:has_ref())

      local f = handle:fileno()
      if f then
        buf:putf("file:      %s\n", f)
      end

      local ty = handle:get_type()
      if ty == "timer" then
        ---@type uv.uv_timer_t
        local timer = handle

        buf:putf("due in:    %s\n", timer:get_due_in())
        buf:putf("repeat:    %s\n", timer:get_repeat())

      elseif ty == "fs_event" then
        ---@type uv.uv_fs_event_t
        local fs_event = handle

        local path = fs_event:getpath()
        if path then
          buf:putf("path:      %s\n", path)
        end
      end

      local data = handle_stats[handle]
      if data then
        if data.plugin then
          buf:putf("plugin:    %s\n", data.plugin)
        end
        buf:putf("filename:  %s\n", data.filename)
        buf:putf("where:     %s\n", data.where)
        buf:putf("uri:       %s\n", data.uri)

        do
          buf:putf("created:   %s\n", data.created)

          local ago = now - data.created
          buf:putf("           (")
          put_time(ago)
          buf:put(" ago)\n")

          local after = data.created - START
          buf:putf("           (")
          put_time(after)
          buf:put(" after startup)\n")
        end

        buf:putf("serial:    %s\n", data.serial)
        if data.buf then
          buf:putf("buf no:    %s\n", data.buf)
          buf:putf("buf name:  %s\n", data.bufname)
        end

        buf:put("\n"):put(data.traceback):put("\n")
      end

      buf:put(sep)
    end

    vim.print(buf:get())
  end,
  {
    nargs = 0,
  }
)

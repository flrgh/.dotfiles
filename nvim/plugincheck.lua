local env = require("my.env")
env.init("script")
local plugins = require("my.plugins")
local cmd = require("my.std.cmd")
local fs = require("my.std.fs")
local trim = require("my.std.string").trim

local list = require("my.std").Set()
local all = {}

local function add_plugin(p)
  if type(p) == "string" then
    add_plugin({ p })

  elseif type(p) == "table" then
    local name = p.name or p[1]

    if list:add(name) then
      table.insert(all, p)
    end

    if type(p.dependencies) == "table" then
      for _, d in ipairs(p.dependencies) do
        add_plugin(d)
      end
    end
  end
end

if true then
  plugins.load(true)
  for _, p in ipairs(plugins.list()) do
    add_plugin(p)
  end
else
  for _, p in ipairs(plugins.SPECS) do
    add_plugin(p)
  end
end

local results = {}

local checking = list.len
local function all_checked()
  assert(checking >= 0)
  return checking == 0
end

local namelen = 0

local procs = {}
for _, p in ipairs(all) do
  local slug = p.name or p[1]
  namelen = math.max(namelen, #slug + 2)

  local name = slug:gsub("^.*/", "")

  local dir = env.nvim.plugins .. "/" .. name
  vim.uv.fs_stat(dir, function(err, st)
    if err or not st then
      checking = checking - 1
      return
    end

    table.insert(procs, assert(cmd.new("git")
      :args({
        "-C", dir,
        "log",
        "-n1",
        "--format=format:%ct"
      })
      :on_stdout_line(function(line, eof)
        if line then
          local ct = assert(tonumber(trim(line)))
          -- convert unix UTC to local ISO8601(ish)
          local text = os.date("%F %T", ct)
          table.insert(results, { slug, text })
        end
      end)))
    checking = checking - 1
  end)
end

vim.wait(1000, all_checked, 10)

local running = {}
local limit = 4
while #running < limit and #procs > 0 do
  table.insert(running, table.remove(procs):run())
end

while #running > 0 do
  table.remove(running, 1):wait()
  local proc = table.remove(procs)
  if proc then
    table.insert(running, proc:run())
  end
end

table.sort(results, function(a, b)
  if a[2] == b[2] then
    return a[1] < b[1]
  end
  return a[2] < b[2]
end)

for _, elem in ipairs(results) do
  io.write(string.format("%-" .. namelen .. "s%s\n", elem[1], elem[2]))
end

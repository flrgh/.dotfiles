local env = require("my.env")
env.init("script")
local plugins = require("my.plugins")

local results = plugins.check()

local namelen = 0
for i = 1, #results do
  local name = results[i][1]
  namelen = math.max(namelen, #name + 2)
end

local fmt = "%-" .. namelen .. "s%s %s\n"

for _, elem in ipairs(results) do
  io.write(string.format(fmt, elem[1], elem[2], elem[3]))
end

return function()
  local path = require("my.std.path")

  local dir = require("my.env").workspace.dir
  local rc = dir .. "/.nvim.lua"

  if not path.exists(rc) then
    return
  end

  local secure = vim.secure

  local src = secure.read(rc)
  if type(src) ~= "string" then
    return
  end

  local fn, err = loadstring(src, ".nvim.lua")
  if not fn then
    vim.schedule(function()
      vim.notify("workspace rc (" .. rc .. ") could not be parsed: " .. tostring(err))
    end)
    return
  end

  local ok
  ok, err = pcall(fn)
  if not ok then
    vim.schedule(function()
      vim.notify("workspace rc (" .. rc .. ") raised: " .. tostring(err))
    end)
    return
  end
end

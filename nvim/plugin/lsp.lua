local const = require("my.constants")

if const.bootstrap or const.headless then
  return
end

require("my.lsp").init()

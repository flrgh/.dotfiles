--- lua repl init
do
  local pcall = pcall
  local require = require

  local ok, term = pcall(require, "term")

  if ok and term.isatty(io.stdout) then
    local pretty
    ok, pretty = pcall(require, "pl.pretty")

    if ok then
      local write = pretty.write

      local fmt = string.format
      local rep = string.rep

      local select = select
      local tostring = tostring
      local type = type
      local print = print

      local s = "%s"
      local space = " "

      local function _tostring(obj)
        if type(obj) == 'table' then
          return write(obj)
        end
        return tostring(obj)
      end

      local function _map(func, n, ...)
        if n == 0 then return end

        local first = select(1, ...)

        if n == 1 then
          return func(first)
        end

        return func(first), _map(func, select(2, ...))
      end

      function _G.pprint(...)
        local n = select("#", ...)
        local tmpl = rep(s, n, space)
        return print(fmt(tmpl, _map(_tostring, n, ...)))
      end
    end
  end
end

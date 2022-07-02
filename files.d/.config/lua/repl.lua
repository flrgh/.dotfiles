--- lua repl init

do
  local function import(mod)
    local ok, imported = pcall(require, mod)
    if ok then
      return imported
    end
  end

  local function interactive()
    local term = import('term')

    if not term then
      return false, 'no lua-term'
    end

    return term.isatty(io.stdout)
  end

  if not interactive() then
    -- we're not in an interactive session, so let's bail on the whole thing
    return
  end

  local _pl = import('pl.import_into')
  if _pl then
    _G.pl = _pl()
  end
end

do
  if not _G.pl then
    print("penlight isn't installed :( no fancy print for you")
    return
  end

  local pl = _G.pl
  local write = pl.pretty.write
  local function _tostring(obj)
    if type(obj) == 'table' then
      return write(obj)
    end
    return tostring(obj)
  end

  local function _map(func, ...)
    local n = select('#', ...)
    if n == 0 then return end
    local first = select(1, ...)
    if n == 1 then
      return func(first)
    end
    return func(first), _map(func, select(2, ...))
  end

  local print = print
  local s = '%s'
  function _G._print(...)
    local fmt = s:rep(select("#", ...), ' ')
    return print(fmt:format(_map(_tostring,...)))
  end
end

if _print then
  _G.old_print = print
  _G.print = _print
end

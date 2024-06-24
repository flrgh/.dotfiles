local _M = {}

-- https://github.com/golang/tools/blob/master/gopls/doc/settings.md

function _M.init()
  return {
    settings = {
      gopls = {
        buildFlags = {
          "-tags=integration",
        },
        gofumpt = true,
      },
    }
  }
end

return _M

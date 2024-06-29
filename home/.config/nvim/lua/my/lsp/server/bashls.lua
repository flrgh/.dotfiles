local _M = {}

function _M.init()
  return {
    settings = {
      bashIde = {
        shellcheckArguments = {
          -- don't warn about using printf with a variable in the template
          -- https://github.com/koalaman/shellcheck/wiki/SC2059
          "-e", "SC2059",

          -- don't warn about checking the last command's return code with `$?`
          -- https://github.com/koalaman/shellcheck/wiki/SC2181
          "-e", "SC2181",
        },

        shfmt = {
          --  -bn       binary ops like && and | may start a line
          binaryNextLine = true,

          --  -ci       switch cases will be indented
          caseIndent = true,

          --  -sr       redirect operators will be followed by a space
          spaceRedirect = true,

          --  -kp       keep column alignment paddings
          keepPadding = true,
        },
      },
    },
  }
end


return _M

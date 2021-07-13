require('formatter').setup({
  filetype = {
    json = {
      function()
        return {
          exe = "jq",
          args = {"."},
          stdin = true,
        }
      end,
    },
  },
})

vim.filetype.add({
  filename = {
    [".envrc"] = "sh",

    ["CMakeLists.txt"] = "cmake",
  },

  pattern = {
    [".*Dockerfile.*"] = "dockerfile",
  },
})

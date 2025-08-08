vim.filetype.add({
  filename = {
    [".envrc"] = "sh",

    ["CMakeLists.txt"] = "cmake",

    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },

  pattern = {
    [".*Dockerfile.*"] = "dockerfile",
    [".*/%.ssh/config%.d/.*"] = "sshconfig",
  },
})

return {
  -- XXX: https://github.com/neovim/nvim-lspconfig/pull/3990
  get_language_id = function(_, ftype)
    if ftype == "yaml.docker-compose" or ftype:lower():find("ya?ml") then
      return "dockercompose"
    else
      return ftype
    end
  end,

  init_options = {
    dockercomposeExperimental = {
      composeSupport = true,
    },
    dockerfileExperimental = {
      removeOverlappingIssues = false,
    },
    telemetry = "off",
  },
}

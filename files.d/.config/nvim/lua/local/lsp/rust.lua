if not require("local.module").exists("rust-tools") then
  return
end

local extend = vim.tbl_deep_extend

return function(conf)

  require("rust-tools").setup({
    tools = {
      autoSetHints = true,
      hover_with_actions = true,
      inlay_hints = {
        show_parameter_hints = false,
        parmeter_hints_prefix = "",
        other_hints_prefix = "",
      },
    },
    server = extend("force", conf, {
    -- https://github.com/rust-lang/rust-analyzer/blob/master/docs/user/generated_config.adoc
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = {
            command = "clippy",
          },
        },
      },
    }),
  })
end

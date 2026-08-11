---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = "tsc"

    local root_dir = config and config.root_dir
    if root_dir then
      local local_cmd = vim.fs.joinpath(root_dir, "node_modules/.bin", cmd)
      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end

    return vim.lsp.rpc.start({ cmd, "--lsp", "--stdio" }, dispatchers)
  end,
}

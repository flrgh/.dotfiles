return function(_, lsp, _)
    if vim.fn.executable("terraform-ls") then
        lsp.terraformls.setup({})
    end
end

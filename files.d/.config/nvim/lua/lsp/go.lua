return function(on_attach, lsp, capabilities)
    if vim.fn.executable("gopls") then
        lsp.gopls.setup {
            on_attach = on_attach,
            capabilities = capabilities,
        }
    end
end

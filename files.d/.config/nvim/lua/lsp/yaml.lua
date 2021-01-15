return function(on_attach, lsp, _)
    if vim.fn.executable("yaml-language-server") then
        lsp.yamlls.setup {
            on_attach = on_attach
        }
    end
end

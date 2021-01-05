return function(on_attach, lsp, _)
    if vim.fn.executable("bash-language-server") then
        lsp.bashls.setup {
            on_attach = on_attach
        }
    end
end

return function(on_attach, lsp, _)
    if vim.fn.executable("pyright") then
        lsp.pyright.setup {
            on_attach = on_attach
        }
    end
end

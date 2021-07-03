return function(on_attach, lsp, _)
    if vim.fn.executable("vscode-json-languageserver") then
        lsp.jsonls.setup {
            cmd = {"vscode-json-languageserver"},
            filetypes = {"json"},
            on_attach = on_attach
        }
    end
end

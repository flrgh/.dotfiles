return function(on_attach, lsp, _)
    if vim.fn.executable("yaml-language-server") then
        lsp.sqlls.setup {
            cmd = { "sql-language-server" },
            on_attach = on_attach
        }
    end
end

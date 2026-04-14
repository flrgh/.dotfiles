$(PKG)/neovim: $(DEP)/neovim nvim/plugins.lock.json
	nvim -l ./nvim/scripts/bootstrap.lua
	$(TOUCH) $@

$(INSTALL_DATA)/nvim/lazy/lazy.nvim: $(PKG)/neovim

$(INSTALL_DATA)/nvim/_bundle: $(PKG)/neovim nvim/plugins.lock.json $(SCRIPT)/neovim-bundle-plugin-files
	$(SCRIPT)/neovim-bundle-plugin-files

.PHONY: neovim
neovim: language-servers \
	$(DEP)/neovim \
	$(INSTALL_DATA)/nvim/lazy/lazy.nvim \
	$(DEP)/tree-sitter \
	$(MISE_DEPS) \
	$(INSTALL_DATA)/nvim/_bundle \
	| .setup

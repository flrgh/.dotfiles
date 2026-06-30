$(INSTALL_BIN)/http: | $(DEP_INSTALLED)/xh
	ln --no-target-directory -sfv "$(shell which xh)" "$@"

$(DEP)/xh: $(INSTALL_BIN)/http


$(INSTALL_BIN)/ripgrep: | $(DEP_INSTALLED)/ripgrep
	ln --no-target-directory -sfv "$(shell which rg)" "$@"

$(DEP)/ripgrep: $(INSTALL_BIN)/ripgrep

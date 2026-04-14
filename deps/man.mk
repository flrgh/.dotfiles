$(INSTALL_MAN)/index.db: \
	$(DEP)/fd \
	$(DEP)/fzf \
	$(DEP)/gh \
	$(DEP)/git-cliff \
	$(DEP)/xh \
	$(DEP)/nfpm \
	$(DEP)/node \
	$(DEP)/pandoc \
	$(DEP)/python \
	$(DEP)/ripgrep \
	$(SCRIPT)/install-man-pages

	mkdir -p "$(dir $@)"
	$(SCRIPT)/install-man-pages
	mandb --user-db

.PHONY: man
man: $(INSTALL_MAN)/index.db

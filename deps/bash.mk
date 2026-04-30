$(BUILD)/bash-facts: $(BUILD)/home/.config/env $(BASH_BUILTINS)
	$(TOUCH) $@

$(BUILD)/home/.bashrc: \
	lib/bash/* bash/* $(SCRIPT)/generate-bashrc \
	$(FZF_BINDINGS) \
	$(DEP)/bash-completion \
	$(DEP)/bat \
	$(DEP)/direnv \
	$(DEP)/fd \
	$(DEP)/gh \
	$(DEP)/http \
	$(DEP)/lsd \
	$(DEP)/lua-utils\
	$(DEP)/ripgrep \
	$(DEP)/shellcheck \
	$(DEP)/shfmt \
	$(DEP)/usage \
	$(DEP)/xh \
	$(MISE_DEPS) \
	direnv \
	| .setup \
	$(BUILD)/home/.config/env

	$(SCRIPT)/generate-bashrc
	$(DIFF) $(INSTALL_PATH)/.bashrc "$@" || true

$(BUILD)/bashrc.md5: $(BUILD)/home/.bashrc
	md5sum "$<" \
		| awk '{print $$1}' \
		> "$@"
	$(TOUCH) --reference "$<" "$@"

$(BUILD)/bash-completion: ./bash/completion/Makefile | $(DEP)/bash-completion
	$(MAKE) -C ./bash/completion all
	$(TOUCH) $@

.PHONY: bash-completion
bash-completion: $(BUILD)/bash-completion | .setup
	$(INSTALL_INTO) $(INSTALL_PATH)/.local/share/bash-completion/completions \
		--mode '0644' \
		$(REPO_ROOT)/build/bash-completion/*
	find $(INSTALL_PATH)/.local/share/bash-completion/completions \
		-type f \
		-empty \
		-delete

.PHONY: bashrc
bashrc: $(BUILD)/home/.bashrc $(BUILD)/bashrc.md5 $(SCRIPT)/notify-bash | $(MISE) .setup
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc
	$(INSTALL) --mode 0644 $(BUILD)/bashrc.md5 $(INSTALL_STATE)/bashrc.md5
	$(INSTALL) --mode 0644 $(BUILD)/bashrc.md5 $(INSTALL_RUNTIME)/bashrc.md5
	$(SCRIPT)/notify-bash

.PHONY: bash
bash: $(DEP)/bash .WAIT bash-completion bashrc | .setup
	./scripts/update-default-shell



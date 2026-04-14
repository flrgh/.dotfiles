DIRENV_BUILD_RC := $(BUILD)/home/direnvrc
$(DIRENV_BUILD_RC): $(DEP)/direnv \
	$(SCRIPT)/build-direnv-rc \
	home/.local/lib/bash/direnv.bash \
	home/.local/lib/bash/direnv/*.bash \
	| .setup symlinks

	mkdir -p $(dir $@)
	$(SCRIPT)/build-direnv-rc > $@

DIRENV_RC := $(INSTALL_PATH)/.config/direnv/direnvrc

.PHONY: direnv
direnv: $(DEP)/direnv $(DIRENV_BUILD_RC)
	$(INSTALL) --mode 0644 $(DIRENV_BUILD_RC) $(DIRENV_RC)

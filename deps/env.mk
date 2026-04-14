$(DEP)/dircolors: $(DEP)/coreutils
	$(TOUCH) --reference "$<" "$@"


$(BUILD)/LS_COLORS: $(DEP)/vivid
	$(MISE) exec vivid -- vivid generate catppuccin-mocha >"$@"
	$(TOUCH) --reference "$<" "$@"


$(BUILD)/home/.config/env: $(MISE_DEPS) lib/bash/* scripts/build-env.sh $(BUILD)/LS_COLORS
	./scripts/build-env.sh
	$(DIFF) $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env || true


.PHONY: env
env: $(BUILD)/home/.config/env $(DEP)/bash | $(MISE) .setup
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.config/env
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.pam_environment

NPM_DEP_FILE := ./deps/package.json
NPM_WANTED    = $(shell jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value)"' < $(NPM_DEP_FILE))
NPM_REMOVE    = $(shell jq -r '._removed // [] | .[]?' < $(NPM_DEP_FILE))

NPM_INSTALLED_CACHE := $(BUILD)/cache/npm-installed.mk

ifneq ($(wildcard $(MISE)),)
-include $(NPM_INSTALLED_CACHE)
$(NPM_INSTALLED_CACHE):
	@mkdir -p $(@D)
	@printf 'NPM_INSTALLED := %s\n' \
		"$$($(NPM) list -g --json | jq -r '[.dependencies | to_entries | .[] | "\(.key)@\(.value.version)"] | join(" ")')" > $@
endif

# Empty default when cache doesn't exist or mise not installed
NPM_INSTALLED ?=

NPM_NEEDED = $(strip $(filter-out $(NPM_INSTALLED),$(NPM_WANTED)))

.PHONY: npm
npm: | $(MISE) .setup
	@_remove="$(NPM_REMOVE)"; \
	if [[ -n $$_remove ]]; then \
		echo "npm - uninstall: $$_remove"; \
		$(NPM) uninstall -g $$_remove; \
		$(RM) $(NPM_INSTALLED_CACHE); \
	fi;
	$(NPM) uninstall -g $(shell jq -r '.name' < $(NPM_DEP_FILE)); \
	_needed="$(NPM_NEEDED)"; \
	if [[ -n $$_needed ]]; then \
		echo "npm - install: $$_needed"; \
		$(NPM) install -g $$_needed; \
		$(MISE) reshim; \
		$(RM) $(NPM_INSTALLED_CACHE); \
	else \
		echo "npm - all packages installed"; \
	fi

.PHONY: __npm-check-updates
__npm-check-updates: | $(MISE)
	command -v ncu || $(NPM) install -g npm-check-updates@latest
	ncu --upgrade --packageFile $(NPM_DEP_FILE)

.PHONY: npm-update
npm-update: __npm-check-updates .WAIT npm

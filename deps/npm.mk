NPM_DEP_FILE := ./deps/package.json
NPM_WANTED    = $(shell jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value)"' < $(NPM_DEP_FILE))

NPM_MAKEFILE := $(lastword $(MAKEFILE_LIST))
NPM_INSTALLED_CACHE := $(BUILD)/cache/npm-installed.mk

NPM_UPDATE_FILTER := \
	reduce (.dependencies | to_entries[]) as $$pkg \
	({ names: [], versions: [] }; \
		.names |= . + [$$pkg.key] \
		| .versions |= . + [ [$$pkg.key, $$pkg.value.version] | join("@") ] \
	) \
	| "NPM_INSTALLED := \(.versions | join(" ") )\nNPM_INSTALLED_NAMES := \(.names | join(" ") )"


ifneq ($(wildcard $(MISE)),)
-include $(NPM_INSTALLED_CACHE)
$(NPM_INSTALLED_CACHE): $(NPM_MAKEFILE)
	$(MKPARENT) $@
	@$(NPM) list -g --json | jq -r '$(NPM_UPDATE_FILTER)' | tee -a $@
endif

# Empty default when cache doesn't exist or mise not installed
NPM_INSTALLED ?=
NPM_INSTALLED_NAMES ?=

.PHONY: .npm-remove
.npm-remove: private UNWANTED = $(shell jq -r '._removed // [] | .[]?' < $(NPM_DEP_FILE))
.npm-remove: private REMOVE := $(filter $(UNWANTED),$(NPM_INSTALLED_NAMES))
.npm-remove: $(NPM_DEP_FILE) | .setup
	@_remove="$(REMOVE)"; \
	if [[ -n $$_remove ]]; then \
		echo "npm (uninstall): removing $$_remove"; \
		$(NPM) uninstall -g $$_remove; \
		$(RM) $(NPM_INSTALLED_CACHE); \
	else \
		echo "npm (uninstall): nothing to remove"; \
	fi;

.PHONY: .npm-install
.npm-install: private NPM_NEEDED = $(strip $(filter-out $(NPM_INSTALLED),$(NPM_WANTED)))
.npm-install: $(NPM_DEP_FILE) | $(MISE) .setup
	@_needed="$(NPM_NEEDED)"; \
	if [[ -n $$_needed ]]; then \
		echo "npm (install): installing $$_needed"; \
		$(NPM) uninstall -g $(shell jq -r '.name' < $(NPM_DEP_FILE)); \
		$(NPM) install -g $$_needed; \
		$(MISE) reshim; \
		$(RM) $(NPM_INSTALLED_CACHE); \
	else \
		echo "npm (install): all packages installed"; \
	fi

.PHONY: npm
npm: .npm-remove .npm-install .setup

.PHONY: .npm-check-updates
.npm-check-updates: | $(MISE)
	command -v ncu || $(NPM) install -g npm-check-updates@latest
	ncu --upgrade --packageFile $(NPM_DEP_FILE)

.PHONY: npm-update
npm-update: .npm-check-updates .WAIT npm

.PHONY: clean-npm
clean-npm:
	$(RM) $(NPM_INSTALLED_CACHE)

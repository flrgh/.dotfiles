MISE_MAKEFILE := $(lastword $(MAKEFILE_LIST))
MISE_CONFIGS := mise.toml home/.config/mise/config.toml

.PRECIOUS: $(MISE)
$(MISE): scripts/install-mise | .setup
	./scripts/install-mise
	$(TOUCH) --reference ./scripts/install-mise $(MISE)

MISE_PACKAGE_FILE := $(BUILD)/cache/mise-packages.mk

ifneq ($(wildcard $(MISE)),)
-include $(MISE_PACKAGE_FILE)
$(MISE_PACKAGE_FILE): $(MISE_MAKEFILE) $(MISE_CONFIGS)
	$(MKPARENT) "$@"
	$(MISE) ls --yes --current --no-header | awk '{ \
		full = $$1; stripped = full; \
		sub(/^github:[^\/]+\//, "", stripped); \
		names = names stripped " "; \
		print "MISE_FULL_" stripped " := " full; \
	} END { \
		print "MISE_PACKAGES := " names; \
	}' | tee $@
endif

# Empty default when mise is not yet installed
MISE_PACKAGES ?=
ALL_DEPS += $(MISE_PACKAGES)
MISE_DEPS := $(addprefix $(DEP)/,$(MISE_PACKAGES))
MISE_ALL := $(PKG)/mise-all
MISE_SHIMS := $(DEP)/.mise-shims


$(MISE_SHIMS): $(MISE) $(MISE_MAKEFILE) $(MISE_PACKAGE_FILE) ./scripts/mise-shims | $(MISE_ALL) $(MISE_DEPS)
	./scripts/mise-shims
	$(TOUCH) "$@"


$(MISE_ALL): $(MISE) $(MISE_PACKAGE_FILE) $(MISE_CONFIGS)
	$(MISE) install --yes
	./scripts/mise-shims
	$(TOUCH) "$@"


$(MISE_DEPS): | $(MISE_ALL)
	$(TOUCH) --reference $(shell $(MISE) where $(MISE_FULL_$(notdir $@))) $@


.PHONY: mise
mise: $(MISE) $(MISE_ALL) .WAIT $(MISE_SHIMS)


.PHONY: .mise-update
.mise-update: $(MISE)
	$(MISE) self-update --yes
	$(MISE) upgrade --yes
	$(RM) $(MISE_SHIMS) $(MISE_ALL)


.PHONY: mise-update
mise-update: .mise-update .WAIT $(MISE_ALL)


.PHONY: clean-mise
clean-mise:
	$(RM) $(MISE_SHIMS) $(MISE_ALL) $(MISE_DEPS) $(MISE_PACKAGE_FILE)

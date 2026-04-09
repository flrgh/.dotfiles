ifneq ($(wildcard $(MISE)),)
-include build/cache/mise-packages.mk
build/cache/mise-packages.mk: mise.toml home/.config/mise/config.toml
	@mkdir -p $(@D)
	@printf 'MISE_PACKAGES := %s\n' \
		"$$($(MISE) ls --yes --current --no-header | awk '{sub(/^github:[^\/]+\//, "", $$1); printf "%s ", $$1}')" > $@
endif

# Empty default when mise is not yet installed
MISE_PACKAGES ?=
ALL_DEPS += $(MISE_PACKAGES)
MISE_DEPS := $(addprefix $(DEP)/,$(MISE_PACKAGES))
MISE_ALL := $(PKG)/mise-all

$(MISE_ALL): $(MISE) mise.toml home/.config/mise/config.toml scripts/mise-shims
	$(MISE) upgrade --yes
	./scripts/mise-shims
	$(TOUCH) "$@"

$(MISE_DEPS): | $(MISE_ALL)
	$(TOUCH) --reference $(shell $(MISE) where $(notdir $@)) $@

.PHONY: mise
mise: $(MISE)
	$(MISE) install --yes
	./scripts/mise-shims

.PHONY: .mise-self-update
.mise-self-update: | $(MISE)
	$(MISE) self-update --yes
	./scripts/mise-shims

.PHONY: mise-update
mise-update: .mise-self-update .WAIT $(MISE_ALL)

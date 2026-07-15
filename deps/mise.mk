MISE_MAKEFILE := $(lastword $(MAKEFILE_LIST))
MISE_CONFIGS := mise.toml home/.config/mise/config.toml
MISE_PKG := .mise-packages
MISE_SHIMS: .mise-shims

.PRECIOUS: $(MISE)
$(MISE): scripts/install-mise | .setup
	$(SCRIPT)/install-mise


MISE_PACKAGE_NAMES := $(shell $(MISE) list --yes --current --no-header | awk '{print $$1}')

# npm:@tree-sitter-grammars/tree-sitter-lua -> tree-sitter-lua
# go:golang.org/x/tools/gopls -> gopls
# node -> node
mise_dep_name = $(notdir $(subst :,/,$(1)))

MISE_DEP_NAMES := $(notdir $(subst :,/,$(MISE_PACKAGE_NAMES)))

define mise_pkg_to_dep =
$(eval MISE_ALIAS_$(call mise_dep_name,$(1)) = $(1))
endef
$(foreach pkg,$(MISE_PACKAGE_NAMES),$(call mise_pkg_to_dep,$(pkg)))

mise_where = $(shell $(MISE) where $(MISE_ALIAS_$(notdir $(1))))

ALL_DEPS += $(MISE_DEP_NAMES)

MISE_DEPS := $(addprefix $(DEP)/,$(MISE_DEP_NAMES))
MISE_DEP_INSTALLED := $(addprefix $(DEP_INSTALLED)/,$(MISE_DEP_NAMES))
MISE_DEP_VERSIONS := $(addprefix $(DEP_VERSION)/,$(MISE_DEP_NAMES))

$(DEP_INSTALLED)/$(MISE_SHIMS): $(DEP_INSTALLED)/$(MISE_PKG)
	$(SCRIPT)/mise-shims
	@$(TOUCH) $@


$(DEP_INSTALLED)/mise: $(MISE)
	@$(TOUCH) --reference "$<" "$@"


$(DEP_VERSION)/mise: $(DEP_INSTALLED)/mise
	$(MISE) version --silent \
		| grep -oE '^([0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2})' \
		> "$@"
	@$(TOUCH) --reference "$(MISE)" "$@"


$(DEP_INSTALLED)/$(MISE_PKG): $(MISE) $(MISE_CONFIGS)
	$(MISE) install --yes
	@$(TOUCH) $@


$(MISE_DEP_INSTALLED): $(DEP_INSTALLED)/$(MISE_PKG)
	@$(TOUCH) --reference $(call mise_where,$@) $@


$(DEP_VERSION)/$(MISE_PKG): $(DEP_INSTALLED)/$(MISE_PKG)
	$(MISE) list --yes --current --no-header \
		| while read -r pkg ver _; do echo "$$ver" > "$(DEP_VERSION)/$${pkg##*[:/]}"; done
	$(TOUCH) $@

$(MISE_DEP_VERSIONS): $(DEP_VERSION)/%: $(DEP_INSTALLED)/% $(DEP_VERSION)/$(MISE_PKG)

$(MISE_DEPS): $(DEP_INSTALLED)/$(MISE_SHIMS)

$(DEP)/mise: $(DEP_INSTALLED)/mise $(DEP_VERSION)/mise $(MISE_DEPS)


.PHONY: mise
mise: $(DEP)/mise


.PHONY: .mise-update
.mise-update: $(MISE)
	$(SCRIPT)/mise-self-update
	$(MISE) upgrade --yes
	$(SCRIPT)/mise-shims


.PHONY: mise-update
mise-update: .mise-update


.PHONY: clean-mise
clean-mise:
	$(RM) \
		$(DEP_INSTALLED)/mise \
		$(DEP_VERSION)/$(MISE) \
		$(MISE_DEP_INSTALLED) \
		$(MISE_DEP_VERSIONS) \
		$(DEP_INSTALLED)/$(MISE_SHIMS) \
		$(DEP_VERSION)/$(MISE_PKG) \
		$(DEP_INSTALLED)/$(MISE_PKG)

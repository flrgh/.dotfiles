UV_PACKAGES := \
    compiledb
ALL_DEPS += $(UV_PACKAGES)
UV_DEPS := $(addprefix $(DEP)/,$(UV_PACKAGES))
UV := $(MISE) exec uv -- uv
UV_TOOLS = $(shell $(UV) tool dir)

$(UV_DEPS): $(DEP)/uv $(DEP)/python $(PKG)/python.cleanup
	$(UV) tool install $(notdir $@)
	$(TOUCH) --reference $(UV_TOOLS)/$(notdir $@) "$@"

.PHONY: uv-update
uv-update: | $(MISE)
	-$(UV) tool uninstall \
		systemd-language-server \
		2>/dev/null
	$(UV) tool upgrade --no-managed-python --all

NEED_PACKAGES := $(notdir $(basename $(wildcard $(REPO_ROOT)/home/.local/share/ineed/drivers/*.sh)))
NEED_DEPS := $(addprefix $(DEP)/,$(NEED_PACKAGES))
ALL_DEPS += $(NEED_PACKAGES)

$(NEED_DEPS): | .setup
	ineed install $(notdir $@)
	$(TOUCH) --reference "$(INSTALL_STATE)/ineed/$(notdir $@).installed-timestamp" "$@"

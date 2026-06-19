NEED_PACKAGES := $(notdir $(basename $(wildcard $(REPO_ROOT)/home/.local/share/ineed/drivers/*.sh)))
NEED_DEP_INSTALLED := $(addprefix $(DEP_INSTALLED)/,$(NEED_PACKAGES))
ALL_DEPS += $(NEED_PACKAGES)


$(NEED_DEP_INSTALLED): | .setup
	ineed install $(notdir $@)
	@$(TOUCH) --reference "$(INSTALL_STATE)/ineed/$(notdir $@).installed-timestamp" "$@"

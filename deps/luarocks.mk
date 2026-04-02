LUAROCKS_PACKAGES := \
    teal-language-server \
    tl
ALL_DEPS += $(LUAROCKS_PACKAGES)
LUAROCKS_DEPS := $(addprefix $(DEP)/,$(LUAROCKS_PACKAGES))

$(LUAROCKS_DEPS): | $(LUAROCKS)
	luarocks install $(notdir $@)
	$(TOUCH) $@

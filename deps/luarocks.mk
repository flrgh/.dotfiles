LUAROCKS := $(INSTALL_BIN)/luarocks

LUAROCKS_PACKAGES := \
	penlight
ALL_DEPS += $(LUAROCKS_PACKAGES)
LUAROCKS_DEPS := $(addprefix $(DEP)/,$(LUAROCKS_PACKAGES))


.PRECIOUS: $(LUAROCKS)
$(LUAROCKS): $(DEP)/lua $(DEP)/luajit .WAIT $(DEP)/luarocks


$(LUAROCKS_DEPS): | $(LUAROCKS)
	luarocks install $(notdir $@)
	$(TOUCH) $@

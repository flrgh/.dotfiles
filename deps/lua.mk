$(DEP)/lua-utils: $(BUILD)/repo/lua-utils.head $(LUAROCKS)
	cd $(USER_REPOS)/lua-utils && luarocks build --force-fast
	$(MKPARENT) "$@"
	$(TOUCH) --reference "$<" "$@"

.PHONY: lua
lua: $(LUAROCKS) $(DEP)/lua-utils

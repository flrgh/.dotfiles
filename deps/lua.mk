$(USER_REPOS)/lua-utils:
	mkdir -p $(dir $@)
	git clone git@github.com:flrgh/lua-utils.git "$@"

.NOTINTERMEDIATE:
$(USER_REPOS)/lua-utils/.git/refs/heads/main: $(USER_REPOS)/lua-utils

$(DEP)/lua-utils: $(USER_REPOS)/lua-utils/.git/refs/heads/main $(LUAROCKS)
	cd ~/git/flrgh/lua-utils && luarocks build --force-fast
	$(MKPARENT) "$@"
	$(TOUCH) --reference "$<" "$@"

.PHONY: lua
lua: $(LUAROCKS) $(DEP)/lua-utils

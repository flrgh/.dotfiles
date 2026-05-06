.PRECIOUS: $(BUILD)/repo/%.clone $(BUILD)/repo/%.pull $(BUILD)/repo/%.head

$(BUILD)/repo/%.clone:
	@$(MKPARENT) "$@"
	@if [ ! -d $(USER_REPOS)/$*/.git ]; then \
	    mkdir -p "$(USER_REPOS)"; \
	    git clone git@github.com:$(GITHUB_USER)/$*.git $(USER_REPOS)/$*; \
	fi
	@touch $@

$(BUILD)/repo/%.pull: $(BUILD)/repo/%.clone
	@$(MKPARENT) "$@"
	@git -C $(USER_REPOS)/$* pull --ff-only --quiet || \
	    printf 'repos.mk: pull failed for %s (continuing)\n' "$*" >&2
	$(TOUCH) "$@"

$(BUILD)/repo/%.head: $(BUILD)/repo/%.clone FORCE | $(BUILD)/repo/%.pull
	@$(MKPARENT) "$@"
	@new=$$(git -C $(USER_REPOS)/$* rev-parse HEAD); \
	 old=$$(cat $@ 2>/dev/null || true); \
	 [ "$$new" = "$$old" ] || printf '%s\n' "$$new" > $@


user-repos: \
	$(BUILD)/repo/.dotfiles.pull \
	$(BUILD)/repo/.ai.pull \
	$(BUILD)/repo/doorbell.pull \
	$(BUILD)/repo/rusty-cli.pull \
	$(BUILD)/repo/resty-community-typedefs.pull \
	$(BUILD)/repo/lua-type-annotations.pull


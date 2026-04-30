# generated with:
#   diff -u \
#     build/fzf/key-bindings-upstream.bash \
#     build/fzf/key-bindings.bash \
#   > patch/fzf-key-bindings.bash.patch
FZF_PATCH            := patch/fzf-key-bindings.bash.patch
FZF_UPSTREAM         := $(BUILD)/fzf/key-bindings-upstream.bash
FZF_BINDINGS         := $(BUILD)/fzf/key-bindings.bash
FZF_BINDINGS_VERSION := $(BUILD)/fzf/key-bindings-version.txt
FZF_MAKEFILE         := $(lastword $(MAKEFILE_LIST))
FZF_BIN              = $(shell mise which -t fzf@latest fzf)

$(FZF_UPSTREAM): $(DEP)/fzf $(FZF_MAKEFILE)
	$(MKPARENT) $@
	-mv -f $@ $@.last 2>/dev/null
	$(FZF_BIN) --bash \
		| sed -n '/### key-bindings.bash ###/,/### end: key-bindings.bash ###/p' \
		> $@

$(FZF_BINDINGS): $(FZF_UPSTREAM) $(FZF_PATCH) $(FZF_MAKEFILE)
	$(MKPARENT) $@
	-mv -f $@ $@.last 2>/dev/null
	-mv -f $(FZF_BINDINGS_VERSION) $(FZF_BINDINGS_VERSION).last 2>/dev/null
	cp -f $(FZF_UPSTREAM) $@
	patch --no-backup-if-mismatch $@ $(FZF_PATCH)
	$(FZF_BIN) --version >$(FZF_BINDINGS_VERSION)

.PHONY: fzf-patch
fzf-patch: $(FZF_BINDINGS)

.PHONY: fzf-clean
fzf-clean:
	$(RM) $(FZF_UPSTREAM) $(FZF_BINDINGS) $(FZF_BINDINGS_VERSION)

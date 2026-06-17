LOCAL_PACKAGES := \
	files-in-package \
	gh-helper \
	ineed \
	package-deps \
	package-info \
	package-rdeps

ALL_DEPS += $(LOCAL_PACKAGES)

$(addprefix $(DEP_INSTALLED)/,$(LOCAL_PACKAGES)): $(DEP_INSTALLED)/%: home/.local/bin/% | .setup
	@$(TOUCH) --reference "$<" "$@"

.PHONY: local
local: $(addprefix $(DEP)/,$(LOCAL_PACKAGES))

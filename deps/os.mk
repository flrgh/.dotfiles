# RPM pipeline: txt -> yaml -> rpm -> install
$(PKG)/os.%.nfpm.yaml: ./deps/rpm-%.txt
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool nfpm "$<" "$@"
	$(TOUCH) --reference "$<" "$@"

$(PKG)/os.%.rpm: $(PKG)/os.%.nfpm.yaml
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool rpm "$<" "$@"
	$(TOUCH) --reference "$<" "$@"

$(PKG)/os/%: $(PKG)/os.%.rpm
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool install "$<"
	$(TOUCH) --reference "$<" "$@"

$(PKG)/os/removed: deps/os-package-removed.txt
	sudo dnf remove -y $(call getlines,$<)
	$(TOUCH) --reference "$<" "$@"

# OS packages use filter-out to avoid double-counting things already claimed
# by other managers. This file MUST be included after all other deps/*.mk files.
OS_COMMON_PACKAGES := $(call getlines,./deps/rpm-common.txt)
OS_COMMON_PACKAGES := $(filter-out $(ALL_DEPS),$(OS_COMMON_PACKAGES))
ALL_DEPS += $(OS_COMMON_PACKAGES)
OS_COMMON_DEPS := $(addprefix $(DEP)/,$(OS_COMMON_PACKAGES))

$(OS_COMMON_DEPS): | $(PKG)/os/common
	$(TOUCH) "$@"

OS_WORKSTATION_PACKAGES := $(call getlines,./deps/rpm-workstation.txt)
OS_WORKSTATION_PACKAGES := $(filter-out $(ALL_DEPS),$(OS_WORKSTATION_PACKAGES))
ALL_DEPS += $(OS_WORKSTATION_PACKAGES)
OS_WORKSTATION_DEPS := $(addprefix $(DEP)/,$(OS_WORKSTATION_PACKAGES))

$(OS_WORKSTATION_DEPS): | $(PKG)/os/workstation
	$(TOUCH) "$@"

.PHONY: os-packages
os-packages: $(PKG)/os/common $(PKG)/os/removed

.PHONY: os-packages-workstation
os-packages-workstation: $(PKG)/os/common $(PKG)/os/workstation $(PKG)/os/removed

.PHONY: os-packages-update
os-packages-update: os-packages
	sudo dnf update -y

.PHONY: os-packages-clean
os-packages-clean:
	$(RM) $(wildcard $PKG/os/*) $(OS_COMMON_DEPS) $(OS_WORKSTATION_DEPS) $(wildcard $(PKG)/os.*)

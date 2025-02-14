export INSTALL_PATH := $(HOME)
export INSTALL_BIN := $(INSTALL_PATH)/.local/bin
export REPO_ROOT = $(PWD)
export DEBUG := $(DEBUG)

CACHE_DIR := $(INSTALL_PATH)/.cache
MISE := $(INSTALL_BIN)/mise

export INSTALL := install --verbose --compare --no-target-directory

export DIFF := diff --suppress-common-lines --suppress-blank-empty \
	--ignore-tab-expansion --ignore-all-space --minimal

OLD_FILES := $(INSTALL_PATH)/.bash_profile $(INSTALL_PATH)/.bash_logout

CREATE_DIRS := \
	.cache .cache/download \
	.config \
	.local \
	.local/bin .local/include .local/lib .local/libexec \
	.local/share .local/var .local/var/log .local/var/log/nvim \
	.local/var/log/lsp .local/share/bash-completion/completions

# gnome-software seems to be doing some weirdness if this directory
# doesn't exist
CREATE_DIRS += .local/share/xdg-desktop-portal/applications

CREATE_DIRS := $(addprefix $(INSTALL_PATH)/,$(CREATE_DIRS))

.DEFAULT: all

.PHONY: all
all: install

.PHONY: install
install: links package post env bashrc

.PHONY: debug
debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)

.PHONY: clean
clean:
	rm -rfv ./build/*

.PHONY: package
package:
	./scripts/run-hooks package

.PHONY: post
post:
	./scripts/run-hooks post

.PHONY: rm-old-files
rm-old-files:
	@for f in $(OLD_FILES); do \
		[[ -e $$f ]] || continue; \
		rm -v "$$f"; \
	done

$(CREATE_DIRS):
	mkdir -v -p $(CREATE_DIRS)

.PHONY: links
links: $(CREATE_DIRS) rm-old-files
	./scripts/cleanup-symlinks
	./scripts/create-symlinks

$(MISE): scripts/install-mise
	./scripts/install-mise
	touch --reference ./scripts/install-mise $(MISE)

.PHONY: mise-upgrade
mise-upgrade: $(MISE) home/.config/mise/config.toml
	$(MISE) self-update --yes

.PHONY: mise-deps
mise-install-deps: $(MISE)
	$(MISE) install

.PHONY: mise
mise: $(MISE)

DIRCOLORS_FNAME := dircolors.256dark
DIRCOLORS_URL := https://raw.githubusercontent.com/seebi/dircolors-solarized/master/$(DIRCOLORS_FNAME)
build/dircolors:
	mkdir -p $(CACHE_DIR)
	./home/.local/bin/cache-get $(DIRCOLORS_URL) $(DIRCOLORS_FNAME)
	cp $(CACHE_DIR)/download/$(DIRCOLORS_FNAME) build/dircolors

build/home/.config/env: links mise-install-deps lib/bash/* scripts/build-env.sh build/dircolors
	./scripts/build-env.sh
	@-$(DIFF) $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env

.PHONY: env
env: $(MISE) build/home/.config/env
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.config/env
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.pam_environment

build/home/.bashrc: mise-install-deps lib/bash/* bash/* hooks/bashrc/*
	$(REPO_ROOT)/scripts/run-hooks bashrc
	@-$(DIFF) $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/home/.bashrc

.PHONY: bashrc
bashrc: links env mise build/home/.bashrc
	$(INSTALL) $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc

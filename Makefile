INSTALL_PATH := $(HOME)
INSTALL_BIN := $(INSTALL_PATH)/.local/bin
INSTALL_DATA := $(INSTALL_PATH)/.local/share
INSTALL_STATE := $(INSTALL_PATH)/.local/state
REPO_ROOT = $(PWD)
DEBUG := $(DEBUG)

# namespace exported vars so that they don't interfere with other build tools
export DOTFILES_INSTALL_PATH := $(INSTALL_PATH)
export DOTFILES_INSTALL_BIN := $(INSTALL_BIN)
export DOTFILES_INSTALL_DATA := $(INSTALL_DATA)
export DOTFILES_INSTALL_STATE := $(INSTALL_STATE)
export DOTFILES_REPO_ROOT := $(REPO_ROOT)
export DOTFILES_DEBUG := $(DEBUG)

# no implicit rules
.SUFFIXES:

CACHE_DIR := $(INSTALL_PATH)/.cache
MISE := $(INSTALL_BIN)/mise
LUAROCKS := $(INSTALL_BIN)/luarocks
LIBEXEC := home/.local/libexec
NPM := $(MISE) exec node -- npm

INSTALL := install --verbose --compare --no-target-directory
INSTALL_INTO := install --verbose --compare --target-directory

RM := ./scripts/files rm
CLEANDIR := ./scripts/files cleandir
MKPARENT := ./scripts/files mkparent
MKDIR := ./scripts/files mkdir
TOUCH := ./scripts/files touch

DIFF := diff --suppress-common-lines --suppress-blank-empty \
	--ignore-tab-expansion --ignore-all-space --minimal

OLD_FILES := $(INSTALL_PATH)/.bash_profile \
	$(INSTALL_PATH)/.bash_logout \
	$(INSTALL_BIN)/*~ \
	$(INSTALL_STATE)/ineed/aws-cli.*

CREATE_DIRS := \
	.cache .cache/download \
	.config \
	.local \
	.local/bin .local/include .local/lib .local/libexec \
	.local/share .local/var .local/var/log .local/var/log/nvim \
	.local/var/log/lsp .local/share/bash-completion/completions

BUILD := build
PKG := $(BUILD)/pkg
NEED := $(PKG)/need
CARGO_PKG := $(PKG)/cargo
PIP_PKG := $(PKG)/pip
LUAROCKS_PKG := $(PKG)/luarocks
HASHICORP_PKG := $(PKG)/hashicorp
MISE_PKG := $(PKG)/mise
MISE_DEPS := $(MISE_PKG)/.default

CARGO_HOME := $(INSTALL_PATH)/.local/cargo
CARGO_BIN := $(CARGO_HOME)/bin
RUSTUP := $(CARGO_HOME)/bin/rustup

# gnome-software seems to be doing some weirdness if this directory
# doesn't exist
CREATE_DIRS += .local/share/xdg-desktop-portal/applications

CREATE_DIRS := $(addprefix $(INSTALL_PATH)/,$(CREATE_DIRS))

.DEFAULT: all

.PHONY: all
all: install

.PHONY: install
install: ssh env rust lua bash docker alacritty golang curl git-config

.PHONY: debug
debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)

.PHONY: clean
clean:
	$(CLEANDIR) $(BUILD)

.PHONY: update
update: clean os-packages-update mise-update rust-update

$(PKG)/os.installed: deps/os-package-installed.txt
	sudo dnf install -y $(shell ./scripts/get-lines ./deps/os-package-installed.txt)
	$(TOUCH) $@

$(PKG)/os.removed: deps/os-package-removed.txt
	sudo dnf remove -y $(shell ./scripts/get-lines ./deps/os-package-removed.txt)
	$(TOUCH) $@

$(PKG)/python: $(MISE) deps/python-packages.txt
	$(MISE) exec python -- pip install --user \
		$(shell ./scripts/get-lines ./deps/python-packages.txt)
	$(TOUCH) $@

$(PKG)/flatpak.remotes: deps/flatpak-remotes.txt
	./scripts/setup-flatpak-remotes
	$(TOUCH) $@

$(PKG)/flatpak.apps.installed: $(PKG)/flatpak.remotes deps/flatpak-apps.txt
	./scripts/install-flatpak-apps
	$(TOUCH) $@

.PHONY: flatpak
flatpak: $(PKG)/flatpak.apps.installed
	@flatpak --user update --noninteractive

$(NEED)/%: | .setup
	ineed install $(notdir $@)
	$(TOUCH) $@

$(PIP_PKG)/%:
	pip install --user $(notdir $@)
	$(TOUCH) $@

$(LUAROCKS_PKG)/%: $(LUAROCKS)
	luarocks install $(notdir $@)
	$(TOUCH) $@


NPM_DEP_FILE := ./deps/npm.json
NPM_WANTED    = $(shell jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value)"' < $(NPM_DEP_FILE))
NPM_INSTALLED = $(shell $(NPM) list -g --json | jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value.version)"')
NPM_NEEDED    = $(strip $(filter-out $(NPM_INSTALLED),$(NPM_WANTED)))

.PHONY: npm
.ONESHELL:
npm: $(MISE) | .setup
	@$(NPM) uninstall -g $(shell jq -r '.name' < $(NPM_DEP_FILE))
	_needed="$(NPM_NEEDED)"
	if [[ -n $$_needed ]]; then
		echo "npm - install: $$_needed"
		$(NPM) install -g $$_needed
		$(MISE) reshim
	else
		echo "npm - all packages installed"
	fi

.PHONY: __npm-check-updates
__npm-check-updates: $(MISE)
	command -v ncu || $(NPM) install -g npm-check-updates@latest
	ncu --upgrade --packageFile $(NPM_DEP_FILE)

.PHONY: npm-update
npm-update: __npm-check-updates .WAIT npm

$(RUSTUP): scripts/install-rust | .setup
	./scripts/install-rust
	@touch --reference ./scripts/install-rust $@

$(CARGO_PKG): $(RUSTUP) scripts/install-cargo-packages
	./scripts/install-cargo-packages
	$(TOUCH) $@

.PHONY: rust
rust: $(RUSTUP) $(CARGO_PKG)

.PHONY: rust-update
rust-update: $(RUSTUP)
	$(RUSTUP) self update
	$(RUSTUP) self upgrade-data
	$(RUSTUP) update
	./scripts/install-cargo-packages

.PHONY: os-packages
os-packages: $(PKG)/os.installed $(PKG)/os.removed

.PHONY: os-packages-update
os-packages-update: os-packages
	sudo dnf update -y

.PHONY: rm-old-files
.ONESHELL:
rm-old-files:
	@for f in $(OLD_FILES); do
		rm -fv "$${f:?}";
	done

.PRECIOUS: $(CREATE_DIRS)
$(CREATE_DIRS):
	mkdir -v -p $@

.PHONY: symlinks
symlinks:
	@./scripts/cleanup-symlinks
	@./scripts/create-symlinks

.PHONY: .setup
.setup: | rm-old-files $(CREATE_DIRS) symlinks

.PRECIOUS: $(MISE)
$(MISE): scripts/install-mise | .setup
	./scripts/install-mise
	touch --reference ./scripts/install-mise $(MISE)

.PRECIOUS: $(LUAROCKS)
$(LUAROCKS): $(NEED)/luarocks

.PHONY: mise-update
mise-update: $(MISE) home/.config/mise/config.toml scripts/mise-shims
	$(MISE) self-update --yes
	$(MISE) upgrade --yes
	./scripts/mise-shims

$(MISE_DEPS): $(MISE) mise.toml home/.config/mise/config.toml scripts/mise-shims
	$(MISE) upgrade --yes
	./scripts/mise-shims
	$(TOUCH) $@

.PHONY: mise
mise: $(MISE)
	$(MISE) install --yes
	./scripts/mise-shims

DIRCOLORS_FNAME := dircolors.256dark
DIRCOLORS_URL := https://raw.githubusercontent.com/seebi/dircolors-solarized/master/$(DIRCOLORS_FNAME)
$(BUILD)/dircolors:
	mkdir -p $(CACHE_DIR)
	./home/.local/bin/cache-get $(DIRCOLORS_URL) $(DIRCOLORS_FNAME)
	cp $(CACHE_DIR)/download/$(DIRCOLORS_FNAME) $@

$(BUILD)/home/.config/env: $(MISE_DEPS) lib/bash/* scripts/build-env.sh $(BUILD)/dircolors
	./scripts/build-env.sh
	@-$(DIFF) $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env

.PHONY: ssh
ssh: | .setup
	./scripts/update-ssh-config

.PHONY: env
env: $(MISE) $(BUILD)/home/.config/env | .setup
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.config/env
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.pam_environment

BASH_BUILTINS := $(BUILD)/bash-builtins
$(BASH_BUILTINS): ./scripts/install-custom-bash-builtins
	./scripts/install-custom-bash-builtins
	$(TOUCH) $@

$(BUILD)/bash-facts: $(BUILD)/home/.config/env $(BASH_BUILTINS)
	./scripts/bashrc-init-facts
	$(TOUCH) $@

$(BUILD)/home/.bashrc: $(BUILD)/bash-facts $(MISE_DEPS) lib/bash/* bash/* hooks/bashrc/* $(NEED)/bat $(NEED)/direnv $(NEED)/bash-completion
	$(REPO_ROOT)/scripts/run-hooks bashrc
	@-$(DIFF) $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/home/.bashrc

$(BUILD)/bash-completion: $(NEED)/bash-completion
	$(MAKE) -C ./bash/completion all
	$(TOUCH) $@

.PHONY: bash-completion
bash-completion: $(BUILD)/bash-completion | .setup
	$(INSTALL_INTO) $(INSTALL_PATH)/.local/share/bash-completion/completions \
		--mode '0644' \
		$(REPO_ROOT)/build/bash-completion/*
	find $(INSTALL_PATH)/.local/share/bash-completion/completions \
		-type f \
		-empty \
		-delete

.PHONY: bashrc
bashrc: $(MISE) $(BUILD)/home/.bashrc | .setup
	$(INSTALL) $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc

.PHONY: bash
bash: bash-completion bashrc | .setup
	./scripts/update-default-shell

$(LUAROCKS_PKG)/teal-language-server: $(LUAROCKS_PKG)/tl

$(HASHICORP_PKG)/%:
	get-hashicorp-binary $(notdir $@) latest
	$(TOUCH) $@

.PHONY: golang
golang: $(NEED)/gopls $(NEED)/gotags | .setup

.PHONY: language-servers
language-servers: npm $(LIBEXEC) \
	$(LUAROCKS_PKG)/teal-language-server \
	$(NEED)/docker-language-server \
	$(NEED)/gopls \
	$(PIP_PKG)/systemd-language-server \
	$(MISE_DEPS) \
	| .setup

$(PKG)/neovim: $(NEED)/neovim nvim/plugins.lock.json
	nvim -l ./nvim/bootstrap.lua
	$(TOUCH) $@

$(INSTALL_DATA)/nvim/lazy/lazy.nvim: $(PKG)/neovim

.PHONY: neovim
neovim: language-servers \
	$(NEED)/neovim \
	$(INSTALL_DATA)/nvim/lazy/lazy.nvim \
	$(NEED)/tree-sitter \
	$(MISE_DEPS) \
	| .setup

.PHONY: lua
lua: $(LUAROCKS)

.PHONY: docker
docker: scripts/update-docker-config $(NEED)/docker-buildx | .setup
	./scripts/update-docker-config

.PRECIOUS: $(CARGO_BIN)/alacritty
$(CARGO_BIN)/alacritty: $(CARGO_PKG)

.PHONY: alacritty
alacritty: $(CARGO_BIN)/alacritty | .setup
	./scripts/update-gsettings
	./scripts/update-default-shell

$(BUILD)/home/.config/curlrc: scripts/build-curlrc
	$(MKPARENT) $@
	./scripts/build-curlrc > $@

$(NEED)/curl: $(PKG)/os.installed

.PHONY: curl
curl: $(NEED)/curl $(BUILD)/home/.config/curlrc | .setup
	$(INSTALL_INTO) $(INSTALL_PATH)/.config $(REPO_ROOT)/build/home/.config/curlrc

.PHONY: git-config
git-config: $(MISE_DEPS) | ssh .setup
	./scripts/update-git-config


export KEYBOARD_GROUP = plugdev
export KEYBOARD_GROUP_ID = 1003

$(BUILD)/zsa-group:
	if ! getent group "$(KEYBOARD_GROUP)" &>/dev/null; then \
	    sudo groupadd --gid "$(KEYBOARD_GROUP_ID)" "$(KEYBOARD_GROUP)"; \
	fi
	if ! getent group "$(KEYBOARD_GROUP)" | grep -q "$(USER)" &>/dev/null; then \
	    sudo usermod --append --groups "$(KEYBOARD_GROUP_ID)" "$(USER)"; \
	fi
	$(TOUCH) $@

$(BUILD)/zsa-udev-rule: ./scripts/zsa-udev-rule
	./scripts/zsa-udev-rule > $@

/etc/udev/rules.d/50-zsa.rules: $(BUILD)/zsa-udev-rule $(BUILD)/zsa-group
	sudo install $(BUILD)/zsa-udev-rule $@

$(BUILD)/keymapp/%:
	./scripts/download-keymapp
	$(TOUCH) $@

$(INSTALL_BIN)/keymapp: $(BUILD)/keymapp/keymapp
	$(INSTALL_INTO) $(INSTALL_BIN) $(BUILD)/keymapp/keymapp

$(INSTALL_DATA)/applications/keymapp.desktop: assets/keymapp.desktop $(BUILD)/keymapp/icon.png $(INSTALL_BIN)/keymapp
	xdg-icon-resource install --size 128 $(BUILD)/keymapp/icon.png application-keymapp
	desktop-file-validate assets/keymapp.desktop
	desktop-file-install --dir="$(INSTALL_DATA)/applications" assets/keymapp.desktop
	update-desktop-database

.PHONY: keymapp
keymapp: /etc/udev/rules.d/50-zsa.rules $(INSTALL_DATA)/applications/keymapp.desktop

COMMON = \
	bash \
	curl \
	docker \
	env \
	git-config \
	golang \
	lua \
	mise \
	neovim \
	npm \
	rust \
	ssh

COMMON_UPDATE = \
		mise-update \
		npm-update \
		os-packages-update \
		rust-update

.PHONY: server
server: $(COMMON) $(NEED)/signalbackup-tools

.PHONY: server-update
server-update: $(COMMON_UPDATE) | server

.PHONY: workstation
workstation: \
	$(COMMON) \
	alacritty \
	flatpak \
	keymapp

.PHONY: workstation-update
workstation-update: server-update | workstation

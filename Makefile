export INSTALL_PATH := $(HOME)
export INSTALL_BIN := $(INSTALL_PATH)/.local/bin
export REPO_ROOT = $(PWD)
export DEBUG := $(DEBUG)

CACHE_DIR := $(INSTALL_PATH)/.cache
MISE := $(INSTALL_BIN)/mise
LUAROCKS := $(INSTALL_BIN)/luarocks
LIBEXEC := home/.local/libexec

export INSTALL := install --verbose --compare --no-target-directory
export INSTALL_INTO := install --verbose --compare --target-directory

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

PKG := build/pkg
NEED := $(PKG)/need
NPM_PKG := $(PKG)/npm
CARGO_PKG := $(PKG)/cargo
PIP_PKG := $(PKG)/pip
LUAROCKS_PKG := $(PKG)/luarocks
HASHICORP_PKG := $(PKG)/hashicorp

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
install: links env rust lua bash docker alacritty golang curl git-config

.PHONY: debug
debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)

.PHONY: clean
clean:
	rm -rfv ./build/*

.PHONY: update
update: clean links os-packages-update mise-update rust-update

$(PKG)/os.installed: deps/os-package-installed.txt
	sudo dnf install -y $(shell ./scripts/get-lines ./deps/os-package-installed.txt)
	@mkdir -p $(dir $@)
	touch $@

$(PKG)/os.removed: deps/os-package-removed.txt
	sudo dnf remove -y $(shell ./scripts/get-lines ./deps/os-package-removed.txt)
	@touch $@

$(PKG)/python: $(MISE) deps/python-packages.txt
	$(MISE) exec python -- pip install --user \
		$(shell ./scripts/get-lines ./deps/python-packages.txt)
	@mkdir -p $(dir $@)
	@touch $@

$(NEED)/%:
	ineed install $(notdir $@)
	@mkdir -p $(dir $@)
	@touch $@

$(PIP_PKG)/%:
	pip install --user $(notdir $@)
	@mkdir -p $(dir $@)
	@touch $@

$(LUAROCKS_PKG)/%:
	luarocks install $(notdir $@)
	@mkdir -p $(dir $@)
	@touch $@

$(NPM_PKG): $(MISE) deps/npm-packages.txt
	$(MISE) exec node -- npm install -g \
		$(shell ./scripts/get-lines ./deps/npm-packages.txt)
	$(MISE) reshim
	@mkdir -p $(dir $@)
	@touch $@

$(RUSTUP): scripts/install-rust
	./scripts/install-rust
	@touch --reference ./scripts/install-rust $@


$(CARGO_PKG): $(RUSTUP) scripts/install-cargo-packages
	./scripts/install-cargo-packages
	@mkdir -p $(dir $@)
	@touch $@

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

$(LUAROCKS): $(NEED)/luarocks

.PHONY: mise-update
mise-update: $(MISE) home/.config/mise/config.toml
	$(MISE) self-update --yes
	$(MISE) upgrade --yes

.PHONY: mise-deps
mise-install-deps: $(MISE)
	$(MISE) install --yes

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

BASH_BUILTINS := timer varsplice version
BASH_BUILTINS := $(addprefix $(INSTALL_PATH)/.local/lib/bash/loadables/, $(BASH_BUILTINS))

.PHONY: bash-builtins
bash-builtins:
	./scripts/install-custom-bash-builtins

build/home/.bashrc: mise-install-deps bash-builtins lib/bash/* bash/* hooks/bashrc/* $(NEED)/bat $(NEED)/direnv $(NEED)/bash-completion
	$(REPO_ROOT)/scripts/run-hooks bashrc
	@-$(DIFF) $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/home/.bashrc

build/bash-completion: links $(NEED)/bash-completion
	$(MAKE) -C ./bash/completion all
	@mkdir -p $(dir $@)
	@touch $@

.PHONY: bash-completion
bash-completion: build/bash-completion
	$(INSTALL_INTO) $(INSTALL_PATH)/.local/share/bash-completion/completions \
		--mode '0644' \
		$(REPO_ROOT)/build/bash-completion/*

.PHONY: bashrc
bashrc: links env mise build/home/.bashrc
	$(INSTALL) $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc

.PHONY: bash
bash: bash-completion bashrc
	./scripts/update-default-shell

$(LUAROCKS_PKG)/teal-language-server: $(LUAROCKS_PKG)/tl

$(HASHICORP_PKG)/%:
	get-hashicorp-binary $(notdir $@) latest
	@mkdir -p $(dir $@)
	@touch $@

.PHONY: golang
golang: $(NEED)/gopls $(NEED)/gotags

.PHONY: language-servers
language-servers: $(NPM_PKG) $(LIBEXEC) \
	$(LUAROCKS_PKG)/teal-language-server \
	$(HASHICORP_PKG)/terraform-ls \
	$(NEED)/gopls \
	$(PIP_PKG)/systemd-language-server

.PHONY: neovim
neovim: language-servers $(NEED)/neovim $(NEED)/tree-sitter $(NEED)/fzf

.PHONY: lua
lua: $(LUAROCKS)

.PHONY: docker
docker: scripts/update-docker-config $(NEED)/docker-buildx
	./scripts/update-docker-config

$(CARGO_BIN)/alacritty: $(CARGO_PKG)

.PHONY: alacritty
alacritty: $(CARGO_BIN)/alacritty
	./scripts/update-gsettings
	./scripts/update-default-shell

build/home/.config/curlrc: scripts/build-curlrc
	mkdir -p $(dir $@)
	./scripts/build-curlrc > $@

$(NEED)/curl: os-packages

.PHONY: curl
curl: $(NEED)/curl build/home/.config/curlrc
	$(INSTALL_INTO) $(INSTALL_PATH)/.config $(REPO_ROOT)/build/home/.config/curlrc

.PHONY: git-config
git-config:
	./scripts/update-git-config

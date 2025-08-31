INSTALL_PATH := $(HOME)
INSTALL_BIN := $(INSTALL_PATH)/.local/bin
INSTALL_VBIN := $(INSTALL_PATH)/.local/vbin
INSTALL_DATA := $(INSTALL_PATH)/.local/share
INSTALL_STATE := $(INSTALL_PATH)/.local/state
INSTALL_LIB := $(INSTALL_PATH)/.local/lib
INSTALL_MAN := $(INSTALL_DATA)/man
USER_REPOS := $(HOME)/git/flrgh
REPO_ROOT = $(CURDIR)
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
COPY := install --verbose --preserve-timestamps --no-target-directory

SCRIPT := ./scripts
RM := $(SCRIPT)/files rm
CLEANDIR := $(SCRIPT)/files cleandir
MKPARENT := $(SCRIPT)/files mkparent
MKDIR := $(SCRIPT)/files mkdir
TOUCH := $(SCRIPT)/files touch

LINES = $(shell $(SCRIPT)/get-lines "$<")

DIFF := diff --suppress-common-lines --suppress-blank-empty \
	--ignore-tab-expansion --ignore-all-space --minimal

OLD_FILES := $(INSTALL_PATH)/.bash_profile \
	$(INSTALL_PATH)/.bash_logout \
	$(INSTALL_BIN)/*~ \
	$(INSTALL_STATE)/ineed/aws-cli.* \
	$(INSTALL_BIN)/tl_* \
	$(INSTALL_BIN)/marksman-linux

CREATE_DIRS := \
	.cache .cache/download \
	.config \
	.local \
	.local/bin .local/include .local/lib .local/libexec \
	.local/share .local/var .local/var/log .local/var/log/nvim \
	.local/var/log/lsp .local/share/bash-completion/completions

BUILD := build
PKG := $(BUILD)/pkg
DEP := $(BUILD)/dep
NEED := $(PKG)/need
CARGO_PKG := $(PKG)/cargo
PIP_PKG := $(PKG)/pip
LUAROCKS_PKG := $(PKG)/luarocks
MISE_PKG := $(PKG)/mise

CARGO_HOME := $(INSTALL_PATH)/.local/cargo
CARGO_BIN := $(CARGO_HOME)/bin
RUSTUP := $(CARGO_BIN)/rustup
CARGO := $(CARGO_BIN)/cargo

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
	@echo PIP_PACKAGES: $(PIP_PACKAGES)
	@echo CARGO_PACKAGES: $(CARGO_PACKAGES)
	@echo NEED_PACKAGES: $(NEED_PACKAGES)
	@echo OS_COMMON_PACKAGES: $(OS_COMMON_PACKAGES)
	@echo ALL_DEPS: $(ALL_DEPS)

.PHONY: clean
clean:
	$(CLEANDIR) $(BUILD)

.PHONY: update
update: clean os-packages-update mise-update rust-update

# generate an nfpm.yaml file for a dep list
$(PKG)/os.%.nfpm.yaml: ./deps/rpm-%.txt
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool nfpm "$<" "$@"
	$(TOUCH) --reference "$<" "$@"

# build an .rpm file for a given nfpm.yaml
$(PKG)/os.%.rpm: $(PKG)/os.%.nfpm.yaml
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool rpm "$<" "$@"
	$(TOUCH) --reference "$<" "$@"

# install an .rpm package
$(PKG)/os/%: $(PKG)/os.%.rpm
	$(MKPARENT) "$@"
	$(SCRIPT)/rpm-tool install "$<"
	$(TOUCH) --reference "$<" "$@"

$(PKG)/os/removed: deps/os-package-removed.txt
	sudo dnf remove -y $(LINES)
	$(TOUCH) --reference "$<" "$@"

$(PKG)/python.cleanup: $(DEP)/python | $(MISE)
	$(SCRIPT)/python-cleanup
	$(TOUCH) --reference "$<" "$@"

PIP_REQUIREMENTS = ./deps/requirements.txt
$(PKG)/python.reinstall: $(DEP)/python $(PKG)/python.cleanup | $(MISE)
	$(MISE) exec python -- pip install --force-reinstall --user -r $(PIP_REQUIREMENTS)
	$(TOUCH) --reference "$<" "$@"

$(PKG)/python: $(PIP_REQUIREMENTS) | $(PKG)/python.reinstall $(MISE)
	$(MISE) exec python -- pip install --user -r $(PIP_REQUIREMENTS)
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

ALL_DEPS =

PIP_PACKAGES = $(shell $(SCRIPT)/get-lines ./deps/python-packages.txt)
ALL_DEPS += $(PIP_PACKAGES)
PIP_DEPS = $(addprefix $(DEP)/,$(PIP_PACKAGES))
$(PIP_DEPS): | $(PKG)/python
	$(TOUCH) "$@"

NEED_PACKAGES = $(notdir $(basename $(wildcard $(REPO_ROOT)/home/.local/share/ineed/drivers/*.sh)))
NEED_DEPS = $(addprefix $(DEP)/,$(NEED_PACKAGES))
ALL_DEPS += $(NEED_PACKAGES)
$(NEED_DEPS): | .setup
	ineed install $(notdir $@)
	$(TOUCH) --reference "$(INSTALL_STATE)/ineed/$(notdir $@).installed-timestamp" "$@"

LUAROCKS_PACKAGES = teal-language-server tl
ALL_DEPS += $(LUAROCKS_PACKAGES)
LUAROCKS_DEPS = $(addprefix $(DEP)/,$(LUAROCKS_PACKAGES))
$(LUAROCKS_DEPS): | $(LUAROCKS)
	luarocks install $(notdir $@)
	$(TOUCH) $@

MISE_PACKAGES = $(shell $(MISE) ls --yes --current --no-header | awk '{print $$1}')
ALL_DEPS += $(MISE_PACKAGES)
MISE_DEPS = $(addprefix $(DEP)/,$(MISE_PACKAGES))
MISE_ALL = $(PKG)/mise-all

CARGO_PACKAGES = $(shell $(SCRIPT)/get-lines ./deps/cargo-packages.txt | sort -u)
ALL_DEPS += $(CARGO_PACKAGES)
CARGO_DEPS = $(addprefix $(DEP)/,$(CARGO_PACKAGES))

OS_COMMON_PACKAGES := $(shell $(SCRIPT)/get-lines ./deps/rpm-common.txt | sort -u)
OS_COMMON_PACKAGES := $(filter-out $(ALL_DEPS),$(OS_COMMON_PACKAGES))
ALL_DEPS += $(OS_COMMON_PACKAGES)
OS_COMMON_DEPS = $(addprefix $(DEP)/,$(OS_COMMON_PACKAGES))
$(OS_COMMON_DEPS): | $(PKG)/os/common
	$(TOUCH) "$@"

OS_WORKSTATION_PACKAGES := $(shell $(SCRIPT)/get-lines ./deps/rpm-workstation.txt | sort -u)
OS_WORKSTATION_PACKAGES := $(filter-out $(ALL_DEPS),$(OS_WORKSTATION_PACKAGES))
ALL_DEPS += $(OS_WORKSTATION_PACKAGES)
OS_WORKSTATION_DEPS = $(addprefix $(DEP)/,$(OS_WORKSTATION_PACKAGES))
$(OS_WORKSTATION_DEPS): | $(PKG)/os/workstation
	$(TOUCH) "$@"

$(DEP)/dircolors: $(DEP)/coreutils
	$(TOUCH) --reference "$<" "$@"

NPM_DEP_FILE := ./deps/package.json
NPM_WANTED    = $(shell jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value)"' < $(NPM_DEP_FILE))
NPM_INSTALLED = $(shell $(NPM) list -g --json | jq -r '.dependencies | to_entries | .[] | "\(.key)@\(.value.version)"')
NPM_NEEDED    = $(strip $(filter-out $(NPM_INSTALLED),$(NPM_WANTED)))

.PHONY: npm
npm: | $(MISE) .setup
	@$(NPM) uninstall -g $(shell jq -r '.name' < $(NPM_DEP_FILE)); \
	_needed="$(NPM_NEEDED)"; \
	if [[ -n $$_needed ]]; then \
		echo "npm - install: $$_needed"; \
		$(NPM) install -g $$_needed; \
		$(MISE) reshim; \
	else \
		echo "npm - all packages installed"; \
	fi

.PHONY: __npm-check-updates
__npm-check-updates: | $(MISE)
	command -v ncu || $(NPM) install -g npm-check-updates@latest
	ncu --upgrade --packageFile $(NPM_DEP_FILE)

.PHONY: npm-update
npm-update: __npm-check-updates .WAIT npm

$(RUSTUP): scripts/install-rust | .setup
	./scripts/install-rust
	touch --reference ./scripts/install-rust $@

$(CARGO_PKG): $(RUSTUP) scripts/install-cargo-packages
	./scripts/install-cargo-packages
	$(TOUCH) $@

$(CARGO_DEPS): $(CARGO_PKG)
	$(TOUCH) --reference "$<" "$@"

.PHONY: rust
rust: $(RUSTUP) $(CARGO_PKG)

.PHONY: rust-update
rust-update: $(RUSTUP)
	$(RUSTUP) self update
	$(RUSTUP) self upgrade-data
	$(RUSTUP) update
	./scripts/install-cargo-packages

.PHONY: os-packages
os-packages: $(PKG)/os/common $(PKG)/os/removed

.PHONY: os-packages-workstation
os-packages-workstation: $(PKG)/os/common $(PKG)/os/workstation $(PKG)/os/removed

.PHONY: os-packages-update
os-packages-update: os-packages
	sudo dnf update -y

$(DEP)/bazel: $(DEP)/bazelisk
	ln -sfv $(shell $(MISE) which bazelisk) $(INSTALL_BIN)/bazel
	$(TOUCH) --reference "$<" "$@"

.PHONY: kong
kong: $(PKG)/os/kong $(DEP)/bazel | .setup

.PHONY: rm-old-files
rm-old-files:
	@for f in $(OLD_FILES); do \
		rm -rfv "$${f:?}"; \
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
	$(TOUCH) --reference ./scripts/install-mise $(MISE)

.PRECIOUS: $(LUAROCKS)
$(LUAROCKS): $(DEP)/lua $(DEP)/luajit .WAIT $(DEP)/luarocks

$(MISE_ALL): $(MISE) mise.toml home/.config/mise/config.toml scripts/mise-shims
	$(MISE) upgrade --yes
	./scripts/mise-shims
	$(TOUCH) "$@"

$(MISE_DEPS): | $(MISE_ALL)
	$(TOUCH) --reference $(shell $(MISE) where $(notdir $@)) $@

.PHONY: mise
mise: $(MISE)
	$(MISE) install --yes
	./scripts/mise-shims

.PHONY: .mise-self-update
.mise-self-update: | $(MISE)
	$(MISE) self-update --yes
	./scripts/mise-shims

.PHONY: mise-update
mise-update: .mise-self-update .WAIT $(MISE_ALL)

$(BUILD)/LS_COLORS: $(DEP)/vivid
	$(MISE) exec vivid -- vivid generate catppuccin-mocha >"$@"
	$(TOUCH) --reference "$<" "$@"

$(BUILD)/home/.config/env: $(MISE_DEPS) lib/bash/* scripts/build-env.sh $(BUILD)/LS_COLORS
	./scripts/build-env.sh
	$(DIFF) $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env || true

.PHONY: ssh
ssh: | .setup
	./scripts/update-ssh-config

.PHONY: env
env: $(BUILD)/home/.config/env | $(MISE) .setup
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.config/env
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.pam_environment

BASH_BUILTIN_CLONE := $(USER_REPOS)/bash-builtin-extras
$(BASH_BUILTIN_CLONE): private REPO := git@github.com:flrgh/bash-builtins.git
$(BASH_BUILTIN_CLONE):
	git clone "$(REPO)" "$@"

BASH_BUILTIN_SRCS = $(shell fd \
	--type file \
	--exclude tests \
	'(\.rs|Cargo\.lock|Cargo\.toml)$$' \
	"$(BASH_BUILTIN_CLONE)" \
)

BASH_BUILTIN_NAMES = varsplice timer version
BASH_BUILTIN_LIBS = $(addsuffix .so,$(addprefix $(BASH_BUILTIN_CLONE)/target/release/lib,$(BASH_BUILTIN_NAMES)))

.PHONY: .bash-builtin-pull
.bash-builtin-pull: $(BASH_BUILTIN_CLONE)
	git -C "$(BASH_BUILTIN_CLONE)" pull

$(BASH_BUILTIN_SRCS): .bash-builtin-pull

$(BASH_BUILTIN_LIBS): $(RUSTUP) $(BASH_BUILTIN_CLONE) .WAIT $(BASH_BUILTIN_SRCS)
	cargo build \
	    --quiet \
	    --keep-going \
	    --manifest-path "$(BASH_BUILTIN_CLONE)"/Cargo.toml \
	    --release \
	    --workspace
	touch $(BASH_BUILTIN_LIBS)

BASH_BUILTINS = $(addprefix $(INSTALL_LIB)/bash/loadables/,$(BASH_BUILTIN_NAMES))
$(BASH_BUILTINS): $(BASH_BUILTIN_LIBS)
	$(INSTALL) "$(BASH_BUILTIN_CLONE)/target/release/lib$(notdir $@).so" \
		"$@"

$(BUILD)/bash-facts: $(BUILD)/home/.config/env $(BASH_BUILTINS)
	$(TOUCH) $@

$(BUILD)/home/.bashrc: \
	lib/bash/* bash/* $(SCRIPT)/generate-bashrc \
	patch/fzf-key-bindings.bash.patch \
	$(DEP)/bash-completion \
	$(DEP)/bat \
	$(DEP)/direnv \
	$(DEP)/fd \
	$(DEP)/fzf \
	$(DEP)/gh \
	$(DEP)/http \
	$(DEP)/lsd \
	$(DEP)/lua-utils\
	$(DEP)/ripgrep \
	$(DEP)/shellcheck \
	$(DEP)/shfmt \
	$(DEP)/usage \
	$(DEP)/xh \
	$(MISE_DEPS) \
	| .setup \
	$(BUILD)/home/.config/env

	$(SCRIPT)/generate-bashrc
	$(DIFF) $(INSTALL_PATH)/.bashrc "$@" || true

$(BUILD)/bashrc.md5: $(BUILD)/home/.bashrc
	md5sum "$<" \
		| awk '{print $$1}' \
		> "$@"
	$(TOUCH) --reference "$<" "$@"

$(BUILD)/bash-completion: | $(DEP)/bash-completion
	$(MAKE) -C ./bash/completion all
	$(TOUCH) $@

$(INSTALL_MAN)/index.db: \
	$(DEP)/fd \
	$(DEP)/fzf \
	$(DEP)/gh \
	$(DEP)/git-cliff \
	$(DEP)/xh \
	$(DEP)/nfpm \
	$(DEP)/node \
	$(DEP)/pandoc \
	$(DEP)/python \
	$(DEP)/ripgrep \
	$(SCRIPT)/install-man-pages

	mkdir -p "$(dir $@)"
	$(SCRIPT)/install-man-pages
	mandb --user-db

.PHONY: man
man: $(INSTALL_MAN)/index.db

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
bashrc: $(BUILD)/home/.bashrc $(BUILD)/bashrc.md5 | $(MISE) .setup
	$(INSTALL) --mode 0644 $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc
	$(INSTALL) --mode 0644 $(BUILD)/bashrc.md5 $(INSTALL_STATE)/bashrc.md5

.PHONY: bash
bash: $(DEP)/bash .WAIT bash-completion bashrc | .setup
	./scripts/update-default-shell

.PHONY: golang
golang: $(DEP)/gopls $(DEP)/gotags | .setup

.PHONY: language-servers
language-servers: npm $(LIBEXEC) \
	$(DEP)/teal-language-server \
	$(DEP)/docker-language-server \
	$(DEP)/gopls \
	$(MISE_DEPS) \
	$(DEP)/compiledb \
	$(DEP)/systemd-language-server \
	$(DEP)/marksman \
	$(DEP)/zls \
	| .setup

$(PKG)/neovim: $(DEP)/neovim nvim/plugins.lock.json
	nvim -l ./nvim/bootstrap.lua
	$(TOUCH) $@

$(INSTALL_DATA)/nvim/lazy/lazy.nvim: $(PKG)/neovim

.PHONY: neovim
neovim: language-servers \
	$(DEP)/neovim \
	$(INSTALL_DATA)/nvim/lazy/lazy.nvim \
	$(DEP)/tree-sitter \
	$(MISE_DEPS) \
	| .setup

$(USER_REPOS)/lua-utils:
	$(MKPARENT) "$@"
	git clone git@github.com:flrgh/lua-utils.git "$@"

.NOTINTERMEDIATE:
$(USER_REPOS)/lua-utils/.git/refs/heads/main: $(USER_REPOS)/lua-utils

$(DEP)/lua-utils: $(USER_REPOS)/lua-utils/.git/refs/heads/main $(LUAROCKS)
	cd ~/git/flrgh/lua-utils && luarocks build --force-fast
	$(MKPARENT) "$@"
	$(TOUCH) --reference "$<" "$@"

.PHONY: lua
lua: $(LUAROCKS) $(DEP)/lua-utils

.PHONY: docker
docker: scripts/update-docker-config $(DEP)/docker-buildx | .setup
	./scripts/update-docker-config

.PHONY: alacritty
alacritty: $(DEP)/alacritty | .setup
	./scripts/update-gsettings
	./scripts/update-default-shell

$(BUILD)/home/.config/curlrc: scripts/build-curlrc
	$(MKPARENT) $@
	./scripts/build-curlrc > $@

$(DEP)/curl: | $(PKG)/os/curl-build-deps
.PHONY: curl
curl: $(DEP)/curl $(BUILD)/home/.config/curlrc | .setup
	$(INSTALL_INTO) $(INSTALL_PATH)/.config $(REPO_ROOT)/build/home/.config/curlrc --mode 0644

.PHONY: git-config
git-config: $(MISE_DEPS) $(DEP)/delta | ssh .setup
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
	os-packages \
	rust \
	ssh

COMMON_UPDATE = \
		mise-update \
		npm-update \
		os-packages-update \
		rust-update

.PHONY: server
server: $(COMMON) $(DEP)/signalbackup-tools

.PHONY: server-update
server-update: $(COMMON_UPDATE) | server

.PHONY: workstation
workstation: \
	$(COMMON) \
	$(PKG)/os/workstation \
	alacritty \
	flatpak \
	keymapp

.PHONY: workstation-update
workstation-update: server-update | workstation

$(DEP)/http: XH := $(shell $(MISE) which xh)
$(DEP)/http: $(DEP)/xh
	ln --no-target-directory -sfv "$(XH)" "$(INSTALL_BIN)"/http
	$(TOUCH) --reference "$<" "$@"

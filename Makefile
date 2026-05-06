include vars.mk

.DEFAULT: common

# no-op phony target to force rebuilding
.PHONY: FORCE
FORCE: ;

.PHONY: debug
debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)
	@echo UV_PACKAGES: $(UV_PACKAGES)
	@echo CARGO_PACKAGES: $(CARGO_PACKAGES)
	@echo NEED_PACKAGES: $(NEED_PACKAGES)
	@echo OS_COMMON_PACKAGES: $(OS_COMMON_PACKAGES)
	@echo ALL_DEPS: $(ALL_DEPS)

.PHONY: clean
clean:
	$(CLEANDIR) $(BUILD)

.PHONY: update
update: clean os-packages-update mise-update cargo-update rust-update


.PHONY: rm-old-files
rm-old-files:
	@for f in $(OLD_FILES); do \
		rm --preserve-root --force --verbose -- "$${f:?}"; \
	done
	@for d in $(OLD_DIRS); do \
		rm --preserve-root --dir --force --verbose "$${d:?}"; \
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


ALL_DEPS =

include deps/repos.mk
include deps/flatpak.mk
include deps/uv.mk
include deps/ineed.mk
include deps/luarocks.mk
include deps/mise.mk
include deps/python.mk
include deps/rust.mk
include deps/cargo.mk
include deps/npm.mk
include deps/os.mk
include deps/bash-builtins.mk
include deps/golang.mk
include deps/direnv.mk
include deps/env.mk
include deps/fzf.mk
include deps/bash.mk
include deps/man.mk
include deps/neovim.mk
include deps/lua.mk
include deps/curl.mk
include deps/keymapp.mk
include deps/docker.mk
include deps/ssh.mk


$(DEP)/bazel: $(DEP)/bazelisk
	ln -sfv bazelisk $(INSTALL_BIN)/bazel
	$(TOUCH) --reference "$<" "$@"

.PHONY: kong
kong: $(PKG)/os/kong $(DEP)/bazel | .setup


.PHONY: language-servers
language-servers: npm $(LIBEXEC) \
	$(DEP)/teal-language-server \
	$(DEP)/docker-language-server \
	$(DEP)/gopls \
	$(MISE_DEPS) \
	$(DEP)/compiledb \
	$(DEP)/systemd-lsp \
	$(DEP)/marksman \
	$(DEP)/zls \
	| .setup

.PHONY: alacritty
alacritty: $(DEP)/alacritty | .setup
	./scripts/update-gsettings
	./scripts/update-default-shell

.PHONY: git-config
git-config: $(MISE_DEPS) $(DEP)/delta | ssh .setup
	./scripts/update-git-config


$(DEP)/nerd-fonts: $(SCRIPT)/install-nerd-fonts
	$(SCRIPT)/install-nerd-fonts
	touch --reference "$<" "$@"


$(DEP)/http: XH = $(shell $(MISE) which xh)
$(DEP)/http: $(DEP)/xh
	ln --no-target-directory -sfv "$(XH)" "$(INSTALL_BIN)"/http
	$(TOUCH) --reference "$<" "$@"


COMMON := \
	bash \
	cargo \
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
	ssh \
	user-repos

COMMON_UPDATE := \
	cargo-update \
	mise-update \
	npm-update \
	os-packages-update \
	rust-update

.PHONY: common
common: $(COMMON)

.PHONY: common-update
common-update: $(COMMON) .WAIT $(COMMON_UPDATE)

.PHONY: server
server: $(COMMON) $(DEP)/signalbackup-tools ssh-agent-switcher

.PHONY: server-update
server-update: $(COMMON_UPDATE) | server

.PHONY: workstation
workstation: \
	$(COMMON) \
	$(PKG)/os/workstation \
	$(DEP)/nerd-fonts \
	alacritty \
	flatpak \
	keymapp

.PHONY: workstation-update
workstation-update: server-update | workstation


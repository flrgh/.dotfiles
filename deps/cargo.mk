CARGO_PKG := .cargo-packages

CARGO_MAKEFILE := $(lastword $(MAKEFILE_LIST))

CARGO_PACKAGES := \
	alacritty \
	bindgen-cli \
	bws \
	cargo-bloat \
	cargo-cache \
	cargo-dist \
	cargo-edit \
	cargo-expand \
	cargo-modules \
	cargo-outdated \
	cargo-release \
	cargo-update \
	cbindgen \
	cross \
	html-to-markdown-cli \
	inferno \
	minijinja-cli \
	systemd-lsp

ALL_DEPS += $(CARGO_PACKAGES)
CARGO_DEPS := $(addprefix $(DEP)/,$(CARGO_PACKAGES))
CARGO_DEP_INSTALLED := $(addprefix $(DEP_INSTALLED)/,$(CARGO_PACKAGES))
CARGO_DEP_VERSIONS := $(addprefix $(DEP_VERSION)/,$(CARGO_PACKAGES))

CARGO_BINSTALL := \
	$(SECRETS_EXEC) \
	cargo binstall \
	--no-confirm \
	--continue-on-failure \
	--disable-strategies quick-install \
	--disable-telemetry \
	--locked \
	--min-tls-version 1.3


.PRECIOUS: $(CARGO)
$(CARGO): $(RUST_INIT)


$(DEP_INSTALLED)/.cargo-packages: $(CARGO_MAKEFILE) $(CARGO)
	$(CARGO_BINSTALL) $(CARGO_PACKAGES)
	$(TOUCH) $(CARGO_DEP_INSTALLED)
	$(TOUCH) "$@"

$(CARGO_DEP_INSTALLED): $(DEP_INSTALLED)/$(CARGO_PKG)


$(DEP_VERSION)/$(CARGO_PKG): $(CARGO_MAKEFILE) $(CARGO) $(DEP_INSTALLED)/$(CARGO_PKG)
	$(CARGO) install --list \
		| sed -nre 's/^([^ ]+)[ ]+v([0-9\.]+):$$/\1\t\2/p' \
		| while read -r pkg ver; do echo "$$ver" > "$(DEP_VERSION)/$$pkg"; done
	$(TOUCH) "$@"

$(CARGO_DEP_VERSIONS): $(DEP_VERSION)/$(CARGO_PKG)


.PHONY: clean-cargo
clean-cargo:
	$(RM) $(CARGO_DEPS) $(CARGO_DEP_INSTALLED) $(CARGO_DEP_VERSIONS) $(DEP_VERSION)/$(CARGO_PKG) $(DEP_INSTALLED)/$(CARGO_PKG)

.PHONY: cargo
cargo: $(CARGO_DEPS)

.PHONY: cargo-update
cargo-update: rust-update
	$(CARGO_BINSTALL) $(CARGO_PACKAGES)

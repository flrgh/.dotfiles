CARGO_PKG := $(PKG)/cargo

CARGO_HOME ?= $(INSTALL_PATH)/.local/cargo
CARGO_BIN ?= $(CARGO_HOME)/bin

CARGO := $(CARGO_BIN)/cargo

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
	cargo-release \
	cargo-update \
	cbindgen \
	cross \
	html-to-markdown-cli \
	inferno \
	minijinja-cli \
	systemd-lsp \
	wasm-pack \
	wasmtime-cli \
	worker-build

ALL_DEPS += $(CARGO_PACKAGES)
CARGO_DEPS := $(addprefix $(DEP)/,$(CARGO_PACKAGES))

CARGO_BINSTALL := \
	cargo binstall \
	--no-confirm \
	--continue-on-failure \
	--disable-telemetry \
	--locked \
	--min-tls-version 1.3

$(CARGO_PKG): $(CARGO_MAKEFILE) $(RUST_INIT)
	$(CARGO_BINSTALL) $(CARGO_PACKAGES)
	$(TOUCH) $@

$(CARGO_DEPS): $(CARGO_PKG)
	$(TOUCH) --reference "$<" "$@"

.PHONY: clean-cargo
clean-cargo:
	$(RM) $(CARGO_PKG)

.PHONY: cargo
cargo: $(CARGO_PKG)

.PHONY: cargo-update
cargo-update: rust-update
	$(CARGO_BINSTALL) $(CARGO_PACKAGES)

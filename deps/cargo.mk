CARGO_PACKAGES := \
    alacritty \
    bindgen-cli \
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

$(RUSTUP): scripts/install-rust | .setup
	./scripts/install-rust
	touch --reference ./scripts/install-rust $@

$(CARGO_PKG): $(RUSTUP) scripts/install-cargo-packages
	./scripts/install-cargo-packages $(CARGO_PACKAGES)
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
	./scripts/install-cargo-packages $(CARGO_PACKAGES)

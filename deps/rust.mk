CARGO_HOME ?= $(INSTALL_PATH)/.local/cargo
CARGO_BIN ?= $(CARGO_HOME)/bin

RUSTUP := $(CARGO_BIN)/rustup

RUSTUP_INIT := $(DEP)/rustup-init.sh
RUST_INIT := $(DEP)/rust-init
RUST_MAKEFILE := $(lastword $(MAKEFILE_LIST))


$(RUSTUP_INIT): private RUSTUP_URL := https://sh.rustup.rs
$(RUSTUP_INIT): | $(DEP)/shellcheck .setup
	curl \
	    --proto '=https' \
	    --tlsv1.3 \
	    --silent \
	    --show-error \
	    --fail \
	    --no-follow \
	    --no-location \
	    --max-time 5 \
	    --connect-timeout 5 \
	    --retry 3 \
	    --url "$(RUSTUP_URL)" \
	    --compressed \
	    --create-dirs \
	    --remove-on-error \
	    --remote-time \
	    --time-cond "$@" \
	    --output "$@"
	$(MISE) exec shellcheck -- shellcheck "$@"


$(RUSTUP): | $(RUSTUP_INIT) .setup
	sh "$(RUSTUP)" \
		-y \
		--no-modify-path \
		--default-host x86_64-unknown-linux-gnu


$(RUST_INIT): $(RUST_MAKEFILE) | $(RUSTUP)
	if $(RUSTUP) target list --installed \
		| grep -qxF wasm32-wasi; \
	then \
		$(RUSTUP) target remove wasm32-wasi; \
	fi

	$(RUSTUP) toolchain install \
		stable \
		nightly

	$(RUSTUP) target add \
		x86_64-unknown-linux-gnu

	# I want to use the nightly toolchain for rust-analyzer, clippy, and the
	# like, but LSP diagnostics are not working when I do this
	$(RUSTUP) component add --toolchain stable \
		cargo \
		clippy \
		rust-analyzer \
		rust-docs \
		rust-std \
		rustc \
		rustfmt

	$(TOUCH) --reference "$(RUST_MAKEFILE)" "$@"


.PHONY: clean-rust
clean-rust:
	$(RM) $(RUSTUP_INIT) $(RUST_INIT)


.PHONY: rust
rust: $(RUST_INIT)


.PHONY: rust-update
rust-update: $(RUST_INIT)
	$(RUSTUP) self update
	$(RUSTUP) self upgrade-data
	$(RUSTUP) update

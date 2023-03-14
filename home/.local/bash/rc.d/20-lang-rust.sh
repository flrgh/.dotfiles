export CARGO_HOME=$HOME/.local/cargo
addPath "$CARGO_HOME"/bin

# https://blog.rust-lang.org/2023/03/09/Rust-1.68.0.html#cargos-sparse-protocol
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

export RUSTUP_HOME=$HOME/.local/rustup
if [[ -d "$RUSTUP_HOME"/bin ]]; then
    addPath "$RUSTUP_HOME"/bin
fi

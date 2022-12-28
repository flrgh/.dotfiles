export CARGO_HOME=$HOME/.local/cargo
addPath "$CARGO_HOME"/bin

export RUSTUP_HOME=$HOME/.local/rustup
if [[ -d "$RUSTUP_HOME"/bin ]]; then
    addPath "$RUSTUP_HOME"/bin
fi

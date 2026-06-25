SECRETS_REPO := .secrets
SECRETS_SRC := $(USER_REPOS)/$(SECRETS_REPO)
SECRETS_HEAD := $(BUILD)/repo/$(SECRETS_REPO).head
SECRETS_BIN := $(INSTALL_BIN)/secrets
SECRETS_RUNTIME_DIR := $(XDG_RUNTIME_DIR)/secrets
SECRETS_ENV := $(SECRETS_RUNTIME_DIR)/env
SECRETS_ENV_CONFIG := $(XDG_CONFIG_HOME)/secrets/bash-env.toml

$(SECRETS_BIN): $(SECRETS_HEAD) | $(RUST_INIT)
	cd $(SECRETS_SRC) && $(CARGO) build --release --locked
	$(INSTALL) $(SECRETS_SRC)/target/release/secrets $@


$(DEP_INSTALLED)/secrets: $(SECRETS_BIN)
	@$(TOUCH) --reference "$<" "$@"


$(SECRETS_RUNTIME_DIR):
	mkdir -p "$@"

.PHONY: .secrets-env
.secrets-env: $(SECRETS_BIN) $(SECRETS_RUNTIME_DIR) $(SECRETS_ENV_CONFIG)
	$(SECRETS_BIN) render $(SECRETS_ENV_CONFIG)

.PHONY: secrets
secrets: $(DEP)/secrets .secrets-env | .setup
	@echo "binary installed at $(SECRETS_BIN)"


.PHONY: clean-secrets
clean-secrets:
	$(RM) $(DEP)/secrets $(DEP_INSTALLED)/secrets $(BASH_COMPLETION)/secrets

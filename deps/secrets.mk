SECRETS_REPO := .secrets
SECRETS_SRC := $(USER_REPOS)/$(SECRETS_REPO)
SECRETS_HEAD := $(BUILD)/repo/$(SECRETS_REPO).head
SECRETS_BIN := $(INSTALL_BIN)/secrets
SECRETS_DEP := $(DEP)/secrets


$(SECRETS_BIN): $(SECRETS_HEAD) | $(RUST_INIT)
	cd $(SECRETS_SRC) && $(CARGO) build --release --locked
	$(INSTALL) $(SECRETS_SRC)/target/release/secrets $@


$(SECRETS_DEP): $(SECRETS_BIN)
	$(TOUCH) --reference "$<" "$@"


.PHONY: secrets
secrets: $(SECRETS_DEP) | .setup
	@echo "binary installed at $(SECRETS_BIN)"


.PHONY: clean-secrets
clean-secrets:
	$(RM) $(SECRETS_DEP)

SSH_AGENT_SWITCHER_NAME := ssh-agent-switcher
SSH_AGENT_SWITCHER_DEP := $(DEP_INSTALLED)/$(SSH_AGENT_SWITCHER_NAME)
SSH_AGENT_SWITCHER_UNIT := $(SSH_AGENT_SWITCHER_NAME).service
SSH_AGENT_SWITCHER_UNIT_PATH := \
	$(INSTALL_CONFIG)/systemd/user/$(SSH_AGENT_SWITCHER_UNIT)


.PHONY: ssh
ssh: | .setup
	./scripts/update-ssh-config


$(SSH_AGENT_SWITCHER_DEP): $(RUST_INIT)
	$(SECRETS_EXEC) \
		cargo binstall \
		--no-confirm \
		--continue-on-failure \
		--disable-strategies quick-install \
		--disable-telemetry \
		--locked \
		--min-tls-version 1.3 \
		$(SSH_AGENT_SWITCHER_NAME)
	@$(TOUCH) $@


.PHONY: ssh-agent-switcher
ssh-agent-switcher: $(SSH_AGENT_SWITCHER_DEP) | .setup
	systemctl --user daemon-reload
	systemctl --user enable --now $(SSH_AGENT_SWITCHER_UNIT)

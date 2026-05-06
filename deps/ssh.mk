SSH_AGENT_SWITCHER_NAME := ssh-agent-switcher
SSH_AGENT_SWITCHER_DEP := $(DEP)/$(SSH_AGENT_SWITCHER_NAME)
SSH_AGENT_SWITCHER_UNIT := $(SSH_AGENT_SWITCHER_NAME).service
SSH_AGENT_SWITCHER_UNIT_PATH := \
	$(INSTALL_CONFIG)/systemd/user/$(SSH_AGENT_SWITCHER_UNIT)


.PHONY: ssh
ssh: | .setup
	./scripts/update-ssh-config


$(SSH_AGENT_SWITCHER_DEP): $(RUST_INIT)
	$(CARGO_BINSTALL) $(SSH_AGENT_SWITCHER_NAME)
	$(TOUCH) $@


.PHONY: ssh-agent-switcher
ssh-agent-switcher: $(SSH_AGENT_SWITCHER_DEP) | .setup
	systemctl --user daemon-reload
	systemctl --user enable --now $(SSH_AGENT_SWITCHER_UNIT)

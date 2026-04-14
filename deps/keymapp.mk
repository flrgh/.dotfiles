export KEYBOARD_GROUP := plugdev
export KEYBOARD_GROUP_ID := 1003

$(BUILD)/zsa-group:
	if ! getent group "$(KEYBOARD_GROUP)" &>/dev/null; then \
	    sudo groupadd --gid "$(KEYBOARD_GROUP_ID)" "$(KEYBOARD_GROUP)"; \
	fi
	if ! getent group "$(KEYBOARD_GROUP)" | grep -q "$(USER)" &>/dev/null; then \
	    sudo usermod --append --groups "$(KEYBOARD_GROUP_ID)" "$(USER)"; \
	fi
	$(TOUCH) $@

$(BUILD)/zsa-udev-rule: ./scripts/zsa-udev-rule
	./scripts/zsa-udev-rule > $@

/etc/udev/rules.d/50-zsa.rules: $(BUILD)/zsa-udev-rule $(BUILD)/zsa-group
	sudo install $(BUILD)/zsa-udev-rule $@

$(BUILD)/keymapp/%:
	./scripts/download-keymapp
	$(TOUCH) $@

$(INSTALL_BIN)/keymapp: $(BUILD)/keymapp/keymapp
	$(INSTALL_INTO) $(INSTALL_BIN) $(BUILD)/keymapp/keymapp

$(INSTALL_DATA)/applications/keymapp.desktop: assets/keymapp.desktop $(BUILD)/keymapp/icon.png $(INSTALL_BIN)/keymapp
	xdg-icon-resource install --size 128 $(BUILD)/keymapp/icon.png application-keymapp
	desktop-file-validate assets/keymapp.desktop
	desktop-file-install --dir="$(INSTALL_DATA)/applications" assets/keymapp.desktop
	update-desktop-database

.PHONY: keymapp
keymapp: /etc/udev/rules.d/50-zsa.rules $(INSTALL_DATA)/applications/keymapp.desktop



$(PKG)/flatpak.remotes: deps/flatpak-remotes.txt
	./scripts/setup-flatpak-remotes
	$(TOUCH) $@

$(PKG)/flatpak.apps.installed: $(PKG)/flatpak.remotes deps/flatpak-apps.txt
	./scripts/install-flatpak-apps
	$(TOUCH) $@

.PHONY: flatpak
flatpak: $(PKG)/flatpak.apps.installed
	@flatpak --user update --noninteractive

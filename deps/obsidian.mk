OBS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

OBS_FLATPAK := md.obsidian.Obsidian
OBS_SOCK_LINK := /run/user/$(UID)/.obsidian-cli.sock
OBS_SOCK_TARGET = /run/user/$(UID)/.flatpak/$(OBS_FLATPAK)/xdg-run/.obsidian-cli.sock
OBS_CONFIG_FILE := $(HOME)/.config/obsidian/obsidian.json
OBS_CONFIG = $(file <$(OBS_CONFIG_FILE))
OBS_CLI_SRC := $(HOME)/.local/share/flatpak/app/$(OBS_FLATPAK)/current/active/files/obsidian-cli
OBS_CLI := $(HOME)/.local/bin/obsidian


$(OBS_SOCK_LINK): $(OBS_MAKEFILE)
	if [[ ! -S $(OBS_SOCK_LINK) ]]; then \
		ln -svf "$(OBS_SOCK_TARGET)" "$(OBS_SOCK_LINK)"; \
	fi
	touch "$(OBS_SOCK_LINK)"


$(OBS_CONFIG_FILE):
	@mkdir -p $(dir $@)
	@test -s "$@" || echo '{}' > "$@"


$(OBS_CLI_SRC): $(PKG)/flatpak.apps.installed


# symlink flatpak-installed CLI into ~/.local/bin
$(OBS_CLI): $(OBS_CLI_SRC)
	ln -sfv "$(OBS_CLI_SRC)" "$@"


# enable CLI access in user-level config file
.PHONY: .obsidian-config
.obsidian-config: $(OBS_CONFIG_FILE)
	_conf='$(OBS_CONFIG)'; if [[ $$(jq -r .cli <<< "$$_conf") != 'true' ]]; then \
		jq -r <<< "$$_conf" >/dev/null \
		&& jq -r '.cli = true' <<< "$$_conf" > "$(OBS_CONFIG_FILE)"; \
	fi


.PHONY: obsidian
obsidian: .obsidian-config $(PKG)/flatpak.apps.installed $(OBS_SOCK_LINK) $(OBS_CLI)

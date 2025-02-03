INSTALL_PATH := $(HOME)
REPO_ROOT = $(PWD)
HOOKS = $(wildcard hooks/*)
DEBUG := $(DEBUG)

.DEFAULT: all

.PHONY: hooks/* debug all install bashrc env clean

.EXPORT_ALL_VARIABLES: hooks/*

all: install

debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)
	@echo HOOKS: $(HOOKS)

clean:
	rm -rf ./build/*

hooks/*:
	./scripts/run-hooks $(notdir $@)

build/home/.config/env: env/* scripts/build-env.sh
	mkdir -p $(REPO_ROOT)/build/home/.config
	./scripts/build-env.sh
	-diff $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env

env: build/home/.config/env
	install --verbose \
		--compare \
		--no-target-directory \
		$(REPO_ROOT)/build/home/.config/env \
		$(INSTALL_PATH)/.config/env

build/home/.bashrc: build/home/.config/env hooks/bashrc
	-diff $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/home/.bashrc

bashrc: build/home/.bashrc
	install --verbose \
		--compare \
		--no-target-directory \
		$(REPO_ROOT)/build/home/.bashrc \
		$(INSTALL_PATH)/.bashrc

install: hooks/pre hooks/package hooks/post hooks/bashrc

INSTALL_PATH := $(HOME)
REPO_ROOT = $(PWD)
HOOKS = $(wildcard hooks/*)
DEBUG := $(DEBUG)

.DEFAULT: all

.PHONY: hooks/* debug all install bashrc

.EXPORT_ALL_VARIABLES: hooks/*

all: install

debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)
	@echo HOOKS: $(HOOKS)

hooks/*:
	./scripts/run-hooks $(notdir $@)

bashrc: hooks/bashrc
	-diff $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/bashrc/.bashrc
	install --verbose \
		--compare \
		--no-target-directory \
		$(REPO_ROOT)/build/bashrc/.bashrc \
		$(INSTALL_PATH)/.bashrc

install: hooks/pre hooks/package hooks/post hooks/bashrc

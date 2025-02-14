export INSTALL_PATH := $(HOME)
export REPO_ROOT = $(PWD)
export DEBUG := $(DEBUG)

export INSTALL := install --verbose --compare --no-target-directory

export DIFF := diff --suppress-common-lines --suppress-blank-empty \
	--ignore-tab-expansion --ignore-all-space --minimal

.DEFAULT: all

.PHONY: all
all: install

.PHONY: install
install: pre packages post env bashrc

.PHONY: debug
debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)

.PHONY: clean
clean:
	rm -rfv ./build/*

.PHONY: pre
pre:
	./scripts/run-hooks pre

.PHONY: package
package:
	./scripts/run-hooks package

.PHONY: post
post:
	./scripts/run-hooks post

build/home/.config/env: lib/bash/* scripts/build-env.sh
	./scripts/build-env.sh
	@-$(DIFF) $(INSTALL_PATH)/.config/env $(REPO_ROOT)/build/home/.config/env

.PHONY: env
env: pre build/home/.config/env
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.config/env
	$(INSTALL) $(REPO_ROOT)/build/home/.config/env $(INSTALL_PATH)/.pam_environment

build/home/.bashrc: lib/bash/* bash/* hooks/bashrc/*
	$(REPO_ROOT)/scripts/run-hooks bashrc
	@-$(DIFF) $(INSTALL_PATH)/.bashrc $(REPO_ROOT)/build/home/.bashrc

.PHONY: bashrc
bashrc: pre env build/home/.bashrc
	$(INSTALL) $(REPO_ROOT)/build/home/.bashrc $(INSTALL_PATH)/.bashrc

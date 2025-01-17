INSTALL_PATH := $(HOME)
REPO_ROOT = $(PWD)

all: install

debug:
	@echo REPO_ROOT: $(REPO_ROOT)
	@echo INSTALL_PATH: $(INSTALL_PATH)


pre-hooks:
	INSTALL_PATH=$(INSTALL_PATH) REPO_ROOT=$(REPO_ROOT) \
		./scripts/run-hooks pre

package-hooks:
	INSTALL_PATH=$(INSTALL_PATH) REPO_ROOT=$(REPO_ROOT) \
		./scripts/run-hooks package
post-hooks:
	INSTALL_PATH=$(INSTALL_PATH) REPO_ROOT=$(REPO_ROOT) \
		./scripts/run-hooks post

bashrc:
	INSTALL_PATH=$(INSTALL_PATH) REPO_ROOT=$(REPO_ROOT) \
		./scripts/run-hooks bashrc

install: pre-hooks package-hooks post-hooks bashrc

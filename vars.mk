USER ?= $(shell logname)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
HOME ?= /home/$(USER)

INSTALL_PATH := $(HOME)
INSTALL_PREFIX := $(HOME)/.local
INSTALL_CONFIG := $(INSTALL_PATH)/.config
INSTALL_BIN := $(INSTALL_PREFIX)/bin
INSTALL_VBIN := $(INSTALL_PREFIX)/vbin
INSTALL_LIB := $(INSTALL_PREFIX)/lib

XDG_RUNTIME_DIR ?= /run/user/$(UID)
INSTALL_RUNTIME := $(XDG_RUNTIME_DIR)

XDG_DATA_HOME := $(INSTALL_PREFIX)/share
INSTALL_DATA := $(XDG_DATA_HOME)
INSTALL_MAN := $(INSTALL_DATA)/man

XDG_STATE_HOME := $(INSTALL_PREFIX)/state
INSTALL_STATE := $(XDG_STATE_HOME)

USER_REPOS := $(HOME)/git/flrgh
REPO_ROOT = $(CURDIR)
DEBUG := $(DEBUG)

# namespace exported vars so that they don't interfere with other build tools
export DOTFILES_INSTALL_PATH := $(INSTALL_PATH)
export DOTFILES_INSTALL_BIN := $(INSTALL_BIN)
export DOTFILES_INSTALL_DATA := $(INSTALL_DATA)
export DOTFILES_INSTALL_STATE := $(INSTALL_STATE)
export DOTFILES_INSTALL_RUNTIME := $(INSTALL_RUNTIME)
export DOTFILES_REPO_ROOT := $(REPO_ROOT)
export DOTFILES_DEBUG := $(DEBUG)

# no implicit rules
.SUFFIXES:

CACHE_DIR := $(INSTALL_PATH)/.cache
MISE := $(INSTALL_BIN)/mise
LIBEXEC := home/.local/libexec
NPM := $(MISE) exec node -- npm

INSTALL := install --verbose --compare --no-target-directory
INSTALL_INTO := install --verbose --compare --target-directory
COPY := install --verbose --preserve-timestamps --no-target-directory

SCRIPT := ./scripts
RM := $(SCRIPT)/files rm
CLEANDIR := $(SCRIPT)/files cleandir
MKPARENT := $(SCRIPT)/files mkparent
MKDIR := $(SCRIPT)/files mkdir
TOUCH := $(SCRIPT)/files touch

getbin = $(firstword $(wildcard $(addsuffix /$(1),$(subst :, ,$(PATH)))))
SED := $(call getbin,sed)

getlines = $(sort $(shell $(SED) -n -r -e 's/^[ ]*([^ #]+).*/\1/p' < "$(1)"))

DIFF := diff --suppress-common-lines --suppress-blank-empty \
	--ignore-tab-expansion --ignore-all-space --minimal

OLD_FILES := $(INSTALL_PATH)/.bash_profile \
	$(INSTALL_PATH)/.bash_logout \
	$(INSTALL_BIN)/*~ \
	$(INSTALL_STATE)/ineed/aws-cli.* \
	$(INSTALL_BIN)/tl_* \
	$(INSTALL_BIN)/marksman-linux \
	$(INSTALL_DATA)/claude/versions/* \
	$(INSTALL_STATE)/ineed/bitwarden-*

# only removed if empty
OLD_DIRS := $(INSTALL_DATA)/claude/versions \
	$(INSTALL_DATA)/claude \
	$(INSTALL_LIB)/node_modules/@anthropic-ai

CREATE_DIRS := \
	.cache .cache/download \
	.config \
	.local \
	.local/bin .local/include .local/lib .local/libexec \
	.local/share .local/var .local/var/log .local/var/log/nvim \
	.local/var/log/lsp .local/share/bash-completion/completions

BUILD := build
PKG := $(BUILD)/pkg
DEP := $(BUILD)/dep
MISE_PKG := $(PKG)/mise

# gnome-software seems to be doing some weirdness if this directory
# doesn't exist
CREATE_DIRS += .local/share/xdg-desktop-portal/applications

CREATE_DIRS := $(addprefix $(INSTALL_PATH)/,$(CREATE_DIRS))



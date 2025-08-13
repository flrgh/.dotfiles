BUILD := ../../build/bash-completion

COMMANDS := \
	ast-grep \
	aws \
	bat \
	bazel \
	bindgen \
	busted \
	bws \
	cargo \
	deck \
	delta \
	docker-language-server \
	files-in-package \
	gh \
	gh-helper \
	hugo \
	ineed \
	kubectl \
	luarocks \
	minijinja-cli \
	mise \
	op \
	openstack \
	package-deps \
	package-info \
	pip \
	pip3 \
	rg \
	rustup \
	sg \
	tree-sitter \
	usage \
	varlink \
	wasmtime \
	yq

COMMANDS := $(foreach cmd, $(COMMANDS), $(shell command -v $(cmd)))
COMMANDS := $(foreach cmd, $(COMMANDS), $(notdir $(cmd)))

COMP_FUNCNAME = __complete_$(subst -,_,$(notdir $@))
COMP_LIST_CMD = $$($(CMD))
COMP_SCRIPT = $(BUILD)/$(notdir $@)
COMP_TEST = bash -n $(COMP_SCRIPT)

define from-command =
	$(CMD) > $(COMP_SCRIPT)
	@$(COMP_TEST)
endef

define from-url =
	cat $(shell cache-get $(URL) "bash-completion-$(notdir $@)") \
		> $(COMP_SCRIPT)
	@$(COMP_TEST)
endef

define from-candidate-list-command =
	@echo '$(COMP_FUNCNAME)() '{                                   > $(COMP_SCRIPT)
	@echo '   local cur=$${COMP_WORDS[$$COMP_CWORD]}'             >> $(COMP_SCRIPT)
	@echo '   mapfile -t COMPREPLY \'                             >> $(COMP_SCRIPT)
	@echo '       < <(compgen -W "$(COMP_LIST_CMD)" -- "$$cur")'  >> $(COMP_SCRIPT)
	@echo '}'                                                     >> $(COMP_SCRIPT)
	@echo 'complete -F $(COMP_FUNCNAME) $(notdir $@)'             >> $(COMP_SCRIPT)
	@$(COMP_TEST)
endef

define completion-command =
	@echo 'complete -C "$(CMD)" $@' > $(COMP_SCRIPT)
	@$(COMP_TEST)
endef

$(BUILD):
	mkdir $(BUILD)

.PHONY: all
all: $(BUILD) $(COMMANDS)

.PHONY: clean
clean:
	rm -rvf $(BUILD)

.PHONY: $(COMMANDS)

pip: CMD = pip completion --bash
pip:
	$(from-command)
pip3: CMD = pip3 completion --bash
pip3:
	$(from-command)
hugo: CMD = hugo completion bash
hugo:
	$(from-command)
openstack: CMD = openstack complete --shell bash
openstack:
	$(from-command)
kubectl: CMD = kubectl completion bash
kubectl:
	$(from-command)
luarocks: CMD = luarocks completion bash
luarocks:
	$(from-command)
gh: CMD = gh completion --shell bash # github cli
gh:
	$(from-command)
op: CMD = op completion bash         # 1password
op:
	$(from-command)
ineed: CMD = ineed _bash_completion
ineed:
	$(from-command)
rustup: CMD = rustup completions bash rustup
rustup:
	$(from-command)
gitsign: CMD = gitsign completion bash
gitsign:
	$(from-command)
deck: CMD = deck completion bash
deck:
	$(from-command)
gh-helper: CMD = gh-helper generate-bash-completion
gh-helper:
	$(from-command)
bindgen: CMD = bindgen --generate-shell-completions bash DUMMY_HEADER_FILE_ARG
bindgen:
	$(from-command)
wasmtime: CMD = wasmtime completion bash
wasmtime:
	$(from-command)
tree-sitter: CMD = tree-sitter complete --shell bash
tree-sitter:
	$(from-command)
varlink: CMD = varlink completions bash
varlink:
	$(from-command)
bat: CMD = bat --completion bash
bat:
	$(from-command)
minijinja-cli: CMD = minijinja-cli --generate-completion bash
minijinja-cli:
	$(from-command)
mise: CMD = mise completion bash
mise:
	$(from-command)
usage: CMD = usage --completions bash
usage:
	$(from-command)

cargo: CMD = rustup completions bash cargo
cargo:
	$(from-command)

bazel: CMD = $(DOTFILES_REPO_ROOT)/scripts/download-bazel-bash-completion
bazel:
	$(from-command)

delta: CMD = delta --generate-completion bash
delta:

yq: CMD = yq shell-completion bash
yq:
	$(from-command)

bws: CMD = bws completions bash
bws:
	$(from-command)

ast-grep: CMD = ast-grep completions bash
ast-grep:
	$(from-command)

sg: CMD = sg completions bash
sg:
	$(from-command)

busted: URL = https://raw.githubusercontent.com/Olivine-Labs/busted/master/completions/bash/busted.bash
busted:
	$(from-url)

LIST_PACKAGE_NAMES = ls-packages --name-only

files-in-package: CMD = $(LIST_PACKAGE_NAMES)
files-in-package:
	$(from-candidate-list-command)

package-info: CMD = $(LIST_PACKAGE_NAMES)
package-info:
	$(from-candidate-list-command)

package-deps: CMD = $(LIST_PACKAGE_NAMES)
package-deps:
	$(from-candidate-list-command)

aws: CMD = $(shell mise which aws_completer)
aws:
	$(completion-command)

docker-language-server: CMD = docker-language-server completion bash
docker-language-server:
	$(from-command)

rg: CMD = mise exec ripgrep -- rg --generate complete-bash
rg:
	$(from-command)

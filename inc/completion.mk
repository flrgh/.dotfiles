BASH_COMPLETION := $(BUILD)/bash-completion
BASH_COMPLETION_INSTALL := $(INSTALL_DATA)/bash-completion/completions

BASH_COMPLETION_FUNCNAME = __complete_$(subst -,_,$(notdir $@))

$(BASH_COMPLETION):
	$(MKDIR) "$@"

define _comp_gen_from_command =
	$(BASH_COMPLETION_ARG) > "$@.tmp"
	@bash -n "$@.tmp"
	@mv "$@.tmp" "$@"
endef

define _comp_gen_complete =
	@echo 'complete -C "$(BASH_COMPLETION_ARG)" $(notdir $@)' > "$@.tmp"
	@bash -n "$@.tmp"
	@mv "$@.tmp" "$@"
endef

define _comp_gen_from_url =
	cat "$(shell cache-get $(BASH_COMPLETION_ARG) "bash-completion-$(notdir $@)")" \
		> "$@.tmp"
	@bash -n "$@.tmp"
	@mv "$@.tmp" "$@"
endef

define _comp_gen_from_file =
	@cat "$(BASH_COMPLETION_ARG)" > "$@.tmp"
	@bash -n "$@.tmp"
	@mv "$@.tmp" "$@"
endef

define _comp_gen_from_candidate_list =
	@echo '$(BASH_COMPLETION_FUNCNAME)() '{                                  > "$@.tmp"
	@echo '   local cur=$${COMP_WORDS[$$COMP_CWORD]}'                       >> "$@.tmp"
	@echo '   mapfile -t COMPREPLY \'                                       >> "$@.tmp"
	@echo '       < <(compgen -W "$$($(BASH_COMPLETION_ARG))" -- "$$cur")'  >> "$@.tmp"
	@echo '}'                                                               >> "$@.tmp"
	@echo 'complete -F $(BASH_COMPLETION_FUNCNAME) $(notdir $@)'            >> "$@.tmp"
	@bash -n "$@.tmp"
	@mv "$@.tmp" "$@"
endef

define _comp
DEP_POST_$(if $(3),$(3),$(1)) += $(BASH_COMPLETION_INSTALL)/$(1)

$(BASH_COMPLETION)/$(1): $(DEP_INSTALLED)/$(if $(3),$(3),$(1)) | $(BASH_COMPLETION)
	$$(_comp_gen_$(2))

$(BASH_COMPLETION_INSTALL)/$(1): $(BASH_COMPLETION)/$(1) | $(BASH_COMPLETION_INSTALL)
	$(COPY) --mode 0644 $$< $$@
endef

# bash completion script generator helpers
#
# called as:
#
# $(eval $(call comp_<type>,<cmd>,<arg>,<dep>))
#
# <dep> names the package/tool that provides <cmd> and is optional (defaults to <cmd>)
#
# <type> determines how <arg> is interpreted:
#
# * command: <arg> is a command that should be executed to _generate_ a bash completion script
#
# * complete: <arg> is a file, evaluates to `complete -C <arg> <cmd>`
#
# * url: <arg> is a url that is downloaded and used as-is as a bash completion script
#
# * candidate_list: <arg> is a command that generates a whitespace-delimited list of completion candidates for <cmd>


define comp_command
$(call _comp,$(1),from_command,$(3))
$(BASH_COMPLETION)/$(1): BASH_COMPLETION_ARG = $(2)
endef

define comp_complete
$(call _comp,$(1),complete,$(3))
$(BASH_COMPLETION)/$(1): BASH_COMPLETION_ARG = $(2)
endef

define comp_url
$(call _comp,$(1),from_url,$(3))
$(BASH_COMPLETION)/$(1): BASH_COMPLETION_ARG = $(2)
endef

define comp_file
$(call _comp,$(1),from_file,$(3))
$(BASH_COMPLETION)/$(1): BASH_COMPLETION_ARG = $(2)
endef

define comp_candidate_list
$(call _comp,$(1),from_candidate_list,$(3))
$(BASH_COMPLETION)/$(1): BASH_COMPLETION_ARG = $(2)
endef

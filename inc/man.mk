MAN := $(BUILD)/man

MAN_TARGETS :=

define _man_install_page
$(INSTALL_MAN)/man1/$(1).1: $(MAN)/man1/$(1).1
	$(COPY) -D --mode 0644 "$$<" "$$@"
DEP_POST_$(2) += $(INSTALL_MAN)/man1/$(1).1
MAN_TARGETS += $(INSTALL_MAN)/man1/$(1).1
endef

# man_command(name, cmd, dep): generate the page by running cmd
define man_command
$(MAN)/man1/$(1).1: $(DEP_INSTALLED)/$(if $(3),$(3),$(1))
	$(MKPARENT) "$$@"
	$$(MAN_ARG) > "$$@.tmp"
	@mv "$$@.tmp" "$$@"
$(MAN)/man1/$(1).1: MAN_ARG = $(2)
$(call _man_install_page,$(1),$(if $(3),$(3),$(1)))
endef

# man_file(name, file, dep): copy an already-built page off disk
define man_file
$(MAN)/man1/$(1).1: $(DEP_INSTALLED)/$(if $(3),$(3),$(1))
	$(MKPARENT) "$$@"
	@cp -L "$$(MAN_ARG)" "$$@.tmp"
	@mv "$$@.tmp" "$$@"
$(MAN)/man1/$(1).1: MAN_ARG = $(2)
$(call _man_install_page,$(1),$(if $(3),$(3),$(1)))
endef

# man_tree(name, dir, dep): symlink dir's man[0-9] section pages into the install
# tree, so dropped/renamed pages surface as dangling links (swept by symlink-tree)
define man_tree
$(MAN)/$(1).installed: $(DEP_INSTALLED)/$(if $(3),$(3),$(1))
	@mkdir -p "$(INSTALL_MAN)"
	$(SYMLINK_TREE) "$$(MAN_SRC)" "$(INSTALL_MAN)"
	@$(TOUCH) "$$@"
$(MAN)/$(1).installed: MAN_SRC = $(2)
DEP_POST_$(if $(3),$(3),$(1)) += $(MAN)/$(1).installed
MAN_TARGETS += $(MAN)/$(1).installed
endef

# man_files(name, dir, dep): dir contains flat section-1 page files
define man_files
$(MAN)/$(1).stamp: $(DEP_INSTALLED)/$(if $(3),$(3),$(1))
	$(CLEANDIR) "$(MAN)/$(1)/man1"
	cp -L "$$(MAN_SRC)"/* "$(MAN)/$(1)/man1"/
	@$(TOUCH) "$$@"
$(MAN)/$(1).stamp: MAN_SRC = $(2)
$(call _man_install_tree,$(1),$(if $(3),$(3),$(1)))
endef

define _man_install_tree
$(MAN)/$(1).installed: $(MAN)/$(1).stamp
	@mkdir -p "$(INSTALL_MAN)"
	cp -RL "$(MAN)/$(1)"/. "$(INSTALL_MAN)"/
	@$(TOUCH) "$$@"
DEP_POST_$(2) += $(MAN)/$(1).installed
MAN_TARGETS += $(MAN)/$(1).installed
endef

MAN_CONV_DEP_copy :=
MAN_CONV_DEP_pandoc := $(DEP)/pandoc
MAN_CONV_DEP_scdoc := $(DEP)/scdoc

# man_fetch(name, repo, tag_prefix, converter, srcpaths, dep):
# 1. fetch the man source(s) from <repo> at tag <tag_prefix><version>
# 2. (optionally) convert with <converter> (copy|pandoc|scdoc)
define man_fetch
$(MAN)/$(1).stamp: $(DEP_VERSION)/$(if $(6),$(6),$(1)) $(MAN_CONV_DEP_$(4))
	$(CLEANDIR) "$(MAN)/$(1)"
	$(FETCH_MAN) "$(2)" "$(3)$$(file <$(DEP_VERSION)/$(if $(6),$(6),$(1)))" "$(4)" "$(MAN)/$(1)" $(5)
	@$(TOUCH) "$$@"
$(call _man_install_tree,$(1),$(if $(6),$(6),$(1)))
endef

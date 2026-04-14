BASH_BUILTIN_CLONE := $(USER_REPOS)/bash-builtin-extras

$(BASH_BUILTIN_CLONE): private REPO := git@github.com:flrgh/bash-builtins.git
$(BASH_BUILTIN_CLONE):
	git clone "$(REPO)" "$@"

BASH_BUILTIN_SRCS := $(shell fd \
	--type file \
	--exclude tests \
	'(\.rs|Cargo\.lock|Cargo\.toml)$$' \
	"$(BASH_BUILTIN_CLONE)" \
)

BASH_BUILTIN_NAMES := varsplice timer version
BASH_BUILTIN_LIBS := $(addsuffix .so,$(addprefix $(BASH_BUILTIN_CLONE)/target/release/lib,$(BASH_BUILTIN_NAMES)))

.PHONY: .bash-builtin-pull
.bash-builtin-pull: $(BASH_BUILTIN_CLONE)
	git -C "$(BASH_BUILTIN_CLONE)" pull

$(BASH_BUILTIN_SRCS): .bash-builtin-pull

$(BASH_BUILTIN_LIBS): $(RUSTUP) $(BASH_BUILTIN_CLONE) .WAIT $(BASH_BUILTIN_SRCS)
	cargo build \
	    --quiet \
	    --keep-going \
	    --manifest-path "$(BASH_BUILTIN_CLONE)"/Cargo.toml \
	    --release \
	    --workspace
	touch $(BASH_BUILTIN_LIBS)

BASH_BUILTINS := $(addprefix $(INSTALL_LIB)/bash/loadables/,$(BASH_BUILTIN_NAMES))
$(BASH_BUILTINS): $(BASH_BUILTIN_LIBS)
	$(INSTALL) "$(BASH_BUILTIN_CLONE)/target/release/lib$(notdir $@).so" \
		"$@"

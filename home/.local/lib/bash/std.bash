declare -g BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[std]++ == 0 )) || return 0

# my bash standard library

# shellcheck source=home/.local/lib/bash/common.bash
source "$BASH_USER_LIB"/common.bash

# shellcheck source=home/.local/lib/bash/var.bash
source "$BASH_USER_LIB"/var.bash

# shellcheck source=home/.local/lib/bash/array.bash
source "$BASH_USER_LIB"/array.bash

# shellcheck source=home/.local/lib/bash/string.bash
source "$BASH_USER_LIB"/string.bash

# shellcheck source=home/.local/lib/bash/loadables.bash
source "$BASH_USER_LIB"/loadables.bash

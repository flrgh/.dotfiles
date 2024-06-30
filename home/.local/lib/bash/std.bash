BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}

# my bash standard library

# shellcheck source=home/.local/lib/bash/common.bash
source "$BASH_USER_LIB"/common.bash

# shellcheck source=home/.local/lib/bash/var.bash
source "$BASH_USER_LIB"/var.bash

# shellcheck source=home/.local/lib/bash/array.bash
source "$BASH_USER_LIB"/array.bash

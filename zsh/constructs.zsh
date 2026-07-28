# Function to check for the presence of a command or tool
# NOTE Better than `which` because it is a built-in, which
#      `which` is not.
have() {
    command -v "$1" >/dev/null 2>&1
}


# Function to run the passed command sequence as root.
# NOTE Depends on `have()`.
run_as_admin() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    elif have sudo; then
        sudo "$@"
    else
        return 1
    fi
}

# Function to output a WARNING message, passed by argument, to stderr.
warn() {
    printf '[WARNING] %s\n' "$1" >&2
}

# Function to output any message, passed by argument, to stderr.
say() {
    printf '%s\n' "$1" >&2
}

# Function to output any message, passed by argument, to stderr - provided
# we're in verbose mode.
say_verbose() {
    if [ "${is_verbose}" ]; then say "$1"; fi
}

# Run a command that should never fail. If the command fails execution,
# it will immediately terminate with an error showing the failing command.
# NOTE `"$@"` expands all the functions args.
ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}
# usage example:
_dir="$(ensure mktemp -d)" || return 1

# Function to display help info
show_help() {
    cat <<EOF
<Help lines here>
EOF
}

# Use `if` clauses even for simple comparisons as they are more clear,
# less errror prone and can be extended more easily, eg.
if [ -z "$1" ]; then err "assert_nz $2"; fi
if ! "$@"; then err "command failed: $*"; fi

# The following construct sets a variable to the value of another if it
# exists, or to a default value if not:
var="${possibly_non_existent_variable:-default_value}"

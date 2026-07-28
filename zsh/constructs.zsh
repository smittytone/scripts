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

# Function to output a WARNING message, passed by argument, to stderr
show_warning() {
    printf '[WARNING] %s\n' "$1" >&2
}

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

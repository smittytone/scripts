#!/usr/bin/env zsh

# version 0.1.2

SPEED_3=19200
SPEED_5=115200

start_ncpd() {
    result=$(/usr/local/bin/ncpd -e -s "${1}" -b "${2}" 2>&1)
}

open_ftp() {
    /usr/local/bin/plpftp
}

speed=NONE
dev=NONE
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style and check for options
    local check_arg=${arg:l}
    if [[ "${check_arg}" = "--help" || "${check_arg}" = "-h" ]]; then
        printf "Usage: psion /path/to/device/ [-5 | -3]\n"
        exit 0
    fi

    local type_arg=${arg:0:2}
    if [[ "${type_arg}" = "-5" && "${speed}" = NONE ]]; then
        speed="${SPEED_5}"
        continue
    fi

    if [[ "${type_arg}" = "-3"  && "${speed}" = NONE ]]; then
        speed="${SPEED_3}"
        continue
    fi

    dev="${arg}"
done

if [ "${speed}" = NONE ]; then
    printf "🛑 No device type specified. Use '-5' or '-3'\n"
    exit 1
fi

if [ "${dev}" = NONE ]; then
    printf "🛑 No device path specified, or no device connected\n"
    exit 2
fi

if [ ! -e "${dev}" ]; then
    printf "🛑 Unknown device path specified: %s\n" "${dev}"
    exit 2
fi

if start_ncpd "${dev}" "${speed}"; then
    sleep 1
    open_ftp
else
    printf "🛑 Could not start ncpd"
    exit 2
fi

exit 0
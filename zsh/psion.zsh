#!/usr/bin/env zsh

SPEED_3_A=19200
SPEED_5_MX=115200

start_ncpd() {
    result=$(/usr/local/bin/ncpd -e -s "${1}" -b "${2}" 2>&1)
}

open_ftp() {
    /usr/local/bin/plpftp
}

speed=NONE
dev=NONE
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    # And check for options first
    local check_arg=${arg:l}
    if [[ "${check_arg}" = "--help" || "${check_arg}" = "-h" ]]; then
        printf "Usage: psion /path/to/device/ [--5mx | --3a]\n"
        exit 0
    fi

    local lc_arg=${arg:l}
    if [[ "${lc_arg}" = "--5mx" && "${speed}" = NONE ]]; then
        speed="${SPEED_5_MX}"
        continue
    fi

    if [[ "${lc_arg}" = "--3a"  && "${speed}" = NONE ]]; then
        speed="${SPEED_3_A}"
        continue
    fi

    dev="${arg}"
done

if [ "${speed}" = NONE ]; then
    printf "🛑 No device type specified. Use '--5mx' or '--3a'\n"
    exit 1
fi

if [ "${dev}" = NONE ]; then
    printf "🛑 No device path specified\n" "${dev}"
    exit 2
fi

if [ ! -e "${dev}" ]; then
    printf "🛑 Unknown device path specified: %s\n" "${dev}"
    exit 2
fi

if start_ncpd "${dev}" "${speed}"; then
    open_ftp
else
    printf "🛑 Could not start ncpd"
    exit 2
fi

exit 0
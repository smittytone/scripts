#!/usr/bin/env zsh

# plpbuild.zsh
#
# plptools build script for macOS 26+
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   0.1.0
# @license   MIT

set -e

macfuse=0
install=0
storenext=0
target=/usr/local/bin

# Process the arguments
for arg in "$@"; do
    if [ "${storenext}" -eq 1 ]; then
        # Previous arg was `-d` (only relevant to installs)
        if [[ "${arg[1]}" == '-' ]]; then
            printf "🛑 Missing install directory.\n"
            exit 1
        fi

        target="${arg}"
        storenext=0
        continue
    fi

    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "${check_arg}" = "--macfuse" || "${check_arg}" = "-m" ]]; then
        macfuse=1
    elif [[ "${check_arg}" = "--install" || "${check_arg}" = "-i" ]]; then
        install=1
    elif [[ "${check_arg}" = "--destination" || "${check_arg}" = "-d" ]]; then
        storenext=1
    else
        printf "🛑 Unknown command %s\n" "${arg}"
        exit 1
    fi
done

printf "\033[32;1mRunning pre-build checks.\033[0m\n"
# Check for Homebrew
if [[ -n "$(which brew | grep 'not found')" ]]; then
    printf "🛑 Homebrew not installed\n"
    exit 1
fi

# Set dependencies
# NOTE commented entry is known formula that's not installed, for testing
dependencies=(autoconf automake coreutils gettext gpg libtool m4 pkgconf readline) # openfasttrace)
# Add MacFuse if --macfuse | -m flag set
if [[ "${macfuse}" -eq 1 ]] dependencies+=(macfuse)

# Check dependencies
for (( i = 1 ; i <= ${#dependencies[@]} ; i++ )); do
    if [ -n "$(brew info "${dependencies[i]}"| grep 'Not installed')" ]; then
        printf "🛑 Dependency ${dependencies[i]} not installed\n"
        exit 1
    fi
done

# Check and set location
ROOT_DIRECTORY="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &> /dev/null && pwd)"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"

if [ -z "$(echo "${ROOT_DIRECTORY}" | grep plp)" ]; then
    printf "🛑 Are you in your plptools directory?\n"
    exit 1
fi

cd "${ROOT_DIRECTORY}"
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
export PATH="$(brew --prefix m4)/bin:$PATH"

r=$(/bin/ls bootstrap 2>&1)
if [ -n "$(echo "${r}" | grep 'No such file or directory')" ]; then
    printf "🛑 Are you sure you're in your plptools directory? (bootstrap missing)\n"
    exit 1
fi

# Prepare build
printf "\033[32;1mPreparing build environment.\033[0m\n"
./bootstrap --skip-po

export CPPFLAGS="-I$(brew --prefix gettext)/include -I$(brew --prefix readline)/include"
export LDFLAGS="-L$(brew --prefix gettext)/lib -L$(brew --prefix readline)/lib"
# Add MacFuse if --macfuse | -m flag set
if [[ "${macfuse}" -eq 1 ]] export LDFLAGS="${LDFLAGS} -F/Library/Filesystems/macfuse.fs/Contents/Frameworks"

# Configure build
printf "\033[32;1mConfiguring build.\033[0m\n"
./configure --prefix="$BUILD_DIRECTORY" CFLAGS="-g -O0" CXXFLAGS="-g -O0"

# Build
printf "\033[32;1mBuilding.\033[0m\n"
make

# Done
printf "✅ Compiled tools located in ${ROOT_DIRECTORY}/plpftp etc.\n"

if [ "${install}" -eq  1 ]; then
    printf "\033[32;1mInstalling to ${target} -- requires password.\033[0m\n"
    sudo cp ncpd/ncpd "${target}"
    sudo cp plpftp/plpftp "${target}"
    sudo cp plpprint/plpprintd "${target}"
    if [[ "${macfuse}" -eq 1 ]] sudo cp plpfuse/plpfuse "${target}"
    sudo cp sisinstall/sisinstall "${target}"
    printf "✅ Compiled tools installed in ${target}\n"
fi
#!/bin/zsh

# packcli
#
# Command line tool release preparation script
#
# THIS VERSION TARGETS APPS BUILD WITH THE SWIFT COMPILER
#
# @author    Tony Smith
# @copyright 2026 Tony Smith
# @version   7.0.0
# @license   TBD


# Present help information
show_help() {
    cat << EOF
packcli -- create a signed and notarized CLI app package

THIS VERSION TARGETS APPS BUILD WITH THE SWIFT COMPILER

This script requires an Apple Developer Account. You will need to set up a 2FA app key
for the Apple ID linked to your Developer Account, and to have saved this key in your
Mac's keychain. Pass the keychain item's name to the script as your profile.

Usage: packcli.zsh [OPTIONS]

Options:
  -s / --source {path}     The location of the target project. Default: current directory.
  -n / --name {name}       The target's name. If no name is supplied, packcli uses
                           the name of the project directory.
  -v / --version {version} The target's version. Default: 1.0.0.
  -b / --bundleid {ID}     The target's bundle ID. packcli will attempt to read this
                           from the project's Info.plist file.
  -p / --profile {name}    The keychain ID for your profile. Use notarytool to generate.
  --pkgcert {name}         Your Apple Developer Installer certificate name, eg.
                           'Developer ID Installer: Fred Bloggs (ABCDEF1234)'.
  --appcert {name}         Your Apple Developer Installer certificate name, eg.
                           'Developer ID Application: Fred Bloggs (ABCDEF1234)'.
  -a / --add {path}        Add scripts to the package. Default: the project's pkgscripts directory.
  -m / --mandir {name}     The name of the project sub-directory containing your man page.
  -z                       Don’t create or upload the package: build app only.
  -i / --image             Create a disk image and add the package to it.
  -d / --debug             Enable debugging messages.
  -h / --help              This help page.

  --pre                    Path to an optional script to run before compilation.
  --post                   Path to an optional script to run after compilation.

EOF
}

# Emit error then exit
show_error_then_exit() {
    printf "⛔️ $1\n" 1>&2
    exit 1
}

# Setup
setopt nomatch
app_name=untitled
app_version=1.0.0
app_dir="$PWD"
scripts_dir="${app_dir}/pkgscripts"
bundle_id=none
profile_name=none
pkg_cert_name=none
app_cert_name=none
pkg_dir=""
base_dmg_path="$HOME/base.sparsebundle"
base_build_dir=".build/out/Products/Release"
man_dir=manpage
prev_arg=NONE
pre_script_path=NONE
post_script_path=NONE
typeset -i is_arg=0
typeset -i add_scripts=0
typeset -i debug=0
typeset -i no_pack=0
typeset -i make_disk=0


# Process the command line arguments
for arg in "$@"; do
    if [[ ${is_arg} -eq 0 ]]; then
        var=${arg:l}
        if [[ "${var}" = "-h" || "${var}" = "--help" ]]; then
            # Display help then bail
            show_help
            exit 0
        elif [[ "${var}" = "-a" || "${var}" = "--add" ]]; then
            is_arg=8
            add_scripts=1
        elif [[ "${var}" = "-d" || "${var}" = "--debug" ]]; then
            debug=1
        elif [[ "${var}" = "-n" || "${var}" = "--name" ]]; then
            # Next arg should be the cli tool name, eg. 'pdfmaker'
            is_arg=2
        elif [[ "${var}" = "-s" || "${var}" = "--source" ]]; then
            # Next arg should be the project folder, eg. '$GIT/pdfmaker'
            is_arg=3
        elif [[ "${var}" = "-b" || "${var}" = "--bundleid" ]]; then
            # Next arg should be the cli tool bundle ID, eg. 'com.bps.pdfmaker'
            is_arg=4
        elif [[ "${var}" = "-v" || "${var}" = "--version" ]]; then
            # Next arg should be the cli tool's version string
            is_arg=5
        elif [[ "${var}" = "-m" || "${var}" = "--mandir" ]]; then
            # Next arg should be the manpage directory
            is_arg=11
        elif [ "${var}" = "--appcert" ]; then
            # Next arg should be the app cert name
            is_arg=10
        elif [ "${var}" = "--pkgcert" ]; then
            # Next arg should be the pkg cert name
            is_arg=7
        elif [[ "${var}" = "-p" || "${var}" = "--profile" ]]; then
            # Next arg should be the the profile name
            is_arg=9
        elif [[ "${var}" = "-x" ]]; then
            # Package a binary
            is_arg=1
        elif [[ "${var}" = "-z" ]]; then
            # Don't create a package
            no_pack=1
        elif [[ "${var}" = "-i" || "${var}" = "--image" ]]; then
            # Don't create a package
            make_disk=1
        elif [ "${var}" = "--pre" ]; then
            # Get pre-build script path
            is_arg=12
        elif [ "${var}" = "--post" ]; then
            # Get post-build script path
            is_arg=13
        else
            # An unknown arg included: warn and bail
            show_error_then_exit "Unknown option (${arg}) included"
        fi

        prev_arg="${arg}"
    else
        if [ "${arg:0:1}" = "-" ]; then
            show_error_then_exit "Missing value for ${prev_arg}"
        fi

        case ${is_arg} in
            1) pkg_dir="${arg}" ;;
            2) app_name="${arg}" ;;
            3) app_dir="${arg}" ;;
            4) bundle_id="${arg}" ;;
            5) app_version="${arg}" ;;
            6) user_name="${arg}" ;;
            7) pkg_cert_name="${arg}" ;;
            8) scripts_dir="${arg}" ;;
            9) profile_name="${arg}" ;;
            10) app_cert_name="${arg}" ;;
            11) man_dir="${arg}" ;;
            12) pre_script_path="${arg}" ;;
            13) post_script_path="${arg}" ;;
            *) show_error_then_exit "Option selected without expected parameter: ${is_arg}" ;;
        esac
        is_arg=0
    fi
done

printf "🎬 Starting the packaging process\n"

# Prelim script to run?
if [ "${pre_script_path}" != NONE ]; then
    [ -e "${pre_script_path}" ] && printf "👟 Running preflight script ${pre_script_path}\n" && "${pre_script_path}"
fi

# Switch to app source directory
cd "${app_dir}" || show_error_then_exit "Could not switch to app directory"

# Set the default app name from the directory name
if [ "${app_name}" = "untitled" ]; then
    app_name="$PWD"
    app_name="${app_name:t}"
fi

# Check bundle ID before we proceed and get the scheme name
# MUST match the bundle ID
if [[ "${bundle_id}" = "none" ]]; then
    plist_path=$(find . -name 'swift.plist')
    if [ -n "${plist_path}" ]; then
        # Extract bundle ID from project info.plist file
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${plist_path}")
    else
        show_error_then_exit "No bundle ID specified or found"
    fi
fi

if [[ ${no_pack} -eq 0 && -z "${pkg_dir}" ]]; then
    # Confirm we have a profile name
    if [ "${profile_name}" = "none" ]; then
        show_error_then_exit "No keychain profile provided"
    fi

    # Confirm we have a pkg cert name
    if [ "${pkg_cert_name}" = "none" ]; then
        show_error_then_exit "You must provide a certificate ID with the --pkgcert switch"
    fi

    # Confirm we have an app cert name
    if [ "${app_cert_name}" = "none" ]; then
        show_error_then_exit "You must provide a certificate ID with the --appcert switch"
    fi

    # Check for script additions
    if [[ "${add_scripts}" -eq 1 && ! -e "${scripts_dir}" ]]; then
        show_error_then_exit "Could not locate scripts directory ${scripts_dir}"
    fi
fi

# Debug output
if [ "${debug}" -eq 1 ]; then
    printf "      App: ${app_name}\n"
    printf "Bundle ID: ${bundle_id}\n"
    printf "  Version: ${app_version}\n"
    printf "     Path: ${app_dir}/${base_build_dir}/${app_name}\n"
    printf "      PKG: ${app_dir}/${base_build_dir}/${app_name}-${app_version}.pkg\n"
    printf "   Scheme: ${app_name}\n"
    if [ "${add_scripts}" -eq 1 ]; then
        printf "  Scripts: ${scripts_dir}\n"
    fi
fi

# Build the package
if [[ -z "${pkg_dir}" ]]; then
    printf "🏗️ Building ${app_name}...\n"
    build_dir="$PWD/.build"
    #rm -rf "${build_dir}"
    if [ "${debug}" -eq 1 ]; then
        swift build -c release -v
    else
        swift build -c release -q
    fi
fi


# Set up packaging
pkg_dir="${base_build_dir}/pkgroot/usr/local/bin"
mkdir -p "${pkg_dir}"

# Exit if no package is required
if [ "${no_pack}" -eq 1 ]; then
    printf "✅ Binary compiled to ${app_dir}/${base_build_dir}/${app_name}\n"
    exit 0
fi

# Build and sign the package
printf "📦 Making and signing the package...\n"
cp ${base_build_dir}/${app_name} ${pkg_dir}

# Sign the code to get a hardened runtime
codesign -s "${app_cert_name}" -o runtime "${pkg_dir}/${app_name}"

if [ "${add_scripts}" -eq 1 ]; then
    success=$(pkgbuild --quiet --scripts "${scripts_dir}" --root "${base_build_dir}/pkgroot" --identifier "${bundle_id}.pkg" --install-location "/" --sign "${pkg_cert_name}" --version "${app_version}" "${base_build_dir}/${app_name}-${app_version}.pkg" 2>&1)
else
    success=$(pkgbuild --quiet --root "${base_build_dir}/pkgroot" --identifier "${bundle_id}.pkg" --install-location "/" --sign "${pkg_cert_name}" --version "${app_version}" "${base_build_dir}/${app_name}-${app_version}.pkg" 2>&1)
fi

if [ "$?" -ne 0 ]; then
    show_error_then_exit "Failed to make the package\n$success"
fi

# Notarize the package by getting the app's bundle ID then calling notarytool
# NOTE altool is now deprecated
printf "💬 Requesting package notarization... this may take some time\n"
n_time=$(date +%s)
response=$(xcrun notarytool submit "${base_build_dir}/${app_name}-${app_version}.pkg" --wait -p "${profile_name}")

# Get the notarization job ID from the response
e_time=$(date +%s)
job_id_line=$(grep -m 1 '  id:' < <(echo -e "${response}"))
job_id=$(echo "${job_id_line}" | cut -d ":" -s -f 2 | cut -d " " -f 2)

if [ "${debug}" -eq  1 ]; then
    n_time=$((e_time - n_time))
    printf "✅ Notarization completed after ${n_time} seconds. Job ID: ${job_id} -> ${response}\n"
fi

# Get the notarization status from the response
status_line=$(grep -m 1 '  status:' < <(echo -e "${response}"))
status_result=$(echo "${status_line}" | cut -d ":" -s -f 2 | cut -d " " -f 2)

if [ "${status_result}" != "Accepted" ]; then
    show_error_then_exit "Notarization failed with status ${status_result}\n${response}"
fi

# Staple the notarization result
printf "🔨 Adding notarization to ${base_build_dir}/${app_name}-${app_version}.pkg\n"
success=$(xcrun stapler staple "${base_build_dir}/${app_name}-${app_version}.pkg")
if [ -z "${success}" ]; then
    show_error_then_exit "Could not staple notarization to app"
fi

# Confirm stapling
printf "📋 Checking notarization to ${base_build_dir}/${app_name}-${app_version}.pkg:\n"
output=$(spctl --assess -vvv --type install "${base_build_dir}/${app_name}-${app_version}.pkg" 2>&1)
result=$(echo "${output}" | grep -m 1 -o 'accepted')

if [ "${result}" != "accepted" ]; then
    show_error_then_exit "App not notarized (${result})"
fi

if [ "${debug}" -eq  1 ]; then
    printf "\n${output}\n\n"
fi

# Make a DMG or copy the files for subsequent use
if [ "${make_disk}" -eq  1 ]; then
    printf "💿 Assembling the disk image...\n"
    dmg_version=$(echo ${app_version} | sed 's/-/_/g' | sed 's/\./_/g')
    hdiutil create "${base_dmg_path}" -size 100MB -type SPARSEBUNDLE -fs HFS+J -volname "${app_name}" -quiet
    hdiutil attach "${base_dmg_path}" -quiet

    # Copy the manpage if present
    [ -d "${app_dir}/${man_dir}" ] && cp "${app_dir}/${man_dir}/"* "/Volumes/${app_name}"

    # Copy the .pkg file
    if cp -RH "${base_build_dir}/${app_name}-${app_version}.pkg" "/Volumes/${app_name}"; then
        hdiutil detach "/Volumes/${app_name}" -quiet
        hdiutil convert "${base_dmg_path}" -format ULMO -o "${HOME}/desktop/${app_name}_${dmg_version}.dmg" -quiet
        rm -rf "${base_dmg_path}"
    else
        show_error_then_exit "Could not copy ${HOME}/desktop/${app_name}-${app_version}.pkg to the DMG"
    fi
else
    printf "📦 Moving package to desktop\n"
    mv "${base_build_dir}/${app_name}-${app_version}.pkg" "${HOME}/desktop/${app_name}-${app_version}.pkg"

    if [ -d "${app_dir}/${man_dir}" ]; then
        printf "📄 Moving man page file to desktop\n"
        cp "${app_dir}/${man_dir}/"* $HOME/desktop
    fi
fi

# Apres-build script to run?
if [ "${post_script_path}" != NONE ]; then
    [ -e "${post_script_path}" ] && printf "👟 Running postflight script ${post_script_path}\n" && "${post_script_path}"
fi

printf "🏁 Packaging process complete\n"
exit 0

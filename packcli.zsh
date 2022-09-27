#!/bin/zsh

#
# packcli
#
# Command line tool release preparation script
#
# @author    Tony Smith
# @copyright 2022 Tony Smith
# @version   4.0.1
# @license   TBD
#


# Simple function to present help information
show_help() {
    echo -e "\npackcli -- create a signed and notarized CLI app package\n"
    echo "This script requires an Apple Developer Account. You will need to set up a 2FA app key"
    echo "for the Apple ID linked to your Developer Account, and to have saved this key in your"
    echo "Mac's keychain. Pass the keychain item's name to the script as your profile."
    echo -e "Usage: packcli.zsh [OPTIONS]\n"
    echo "Options:"
    echo    "  -s / --source {path}     The location of the target project. Default: current directory."
    echo    "  -n / --name {name}       The target's name. If no name is supplied, packcli uses"
    echo    "                           the name of the project directory."
    echo    "  -v / --version {version} The target's version. Default: 1.0.0."
    echo    "  -b / --bundleid {ID}     The target's bundle ID. packcli will attempt to read this"
    echo    "                           from the project's Info.plist file."
    echo    "  -p / --profile {name}    The keychain ID for your profile. Use notarytool to generate."
    echo    "  -c / --cert {name}       Your Apple Developer Installer certificate name, eg."
    echo    "                           'Developer ID Installer: Fred Bloggs (ABCDEF1234)'."
    echo    "  -a / --add {path}        Add scripts to the package. Default: the project's pkgscripts directory."
    echo    "  -z                       Build the app but do not package it."
    echo    "  -d / --debug             Enable debugging messages."
    echo -e "  -h / --help              This help page.\n"
}

# Emit error then exit
show_error_then_exit() {
    echo "[ERROR] $1 " 1>&2
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
cert_name=none
typeset -i is_arg=0
typeset -i add_scripts=0
typeset -i debug=0
typeset -i no_pack=0

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
        elif [[ "${var}" = "-c" || "${var}" = "--cert" ]]; then
            # Next arg should be the cert name
            is_arg=7
        elif [[ "${var}" = "-p" || "${var}" = "--profile" ]]; then
            # Next arg should be the the profile name
            is_arg=9
        elif [[ "${var}" = "-z" ]]; then
            # Don't create a package
            no_pack=1
        else
            # An unknown arg included: warn and bail
            show_error_then_exit "Unknown option (${arg}) included"
        fi
    else
        case ${is_arg} in
            2) app_name="${arg}" ;;
            3) app_dir="${arg}" ;;
            4) bundle_id="${arg}" ;;
            5) app_version="${arg}" ;;
            6) user_name="${arg}" ;;
            7) cert_name="${arg}" ;;
            8) scripts_dir="${arg}" ;;
            9) profile_name="${arg}" ;;
            *) show_error_then_exit "Option selected without expected parameter: ${is_arg}" ;;
        esac
        is_arg=0
    fi
done

# Switch to app source directory
cd "${app_dir}" || show_error_then_exit "Could not switch to app directory"

# FROM 4.0.0 -- Check bundle ID before we proceed
if [[ "${bundle_id}" = "none" ]]; then
    plist_path=$(find . -name 'Info.plist')
    if [[ -n "${plist_path}" ]]; then
        # Extract bundle ID from project info.plist file
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${plist_path}")
    else
        show_error_then_exit "No bundle ID specified or found"
    fi
fi

# FROM 4.0.0 -- Correctly set default app name
if [[ "${app_name}" = "untitled" ]]; then
    app_name="$PWD"
    app_name="${app_name:t}"
fi

if [[ ${no_pack} -eq 0 ]]; then
    # FROM 4.0.0 -- Confirm we have a profile name
    if [[ "${profile_name}" = "none" ]]; then
        show_error_then_exit "No keychain profile provided"
    fi

    # FROM 3.1.0 -- Confirm we have a cert name
    if [[ "${cert_name}" = "none" ]]; then
        show_error_then_exit "You must provide a certificate ID with the -c/--cert switch"
    fi

    # Check for script additions
    if [[ ${add_scripts} -eq 1 ]]; then
        if [[ ! -e "${scripts_dir}" ]]; then
            show_error_then_exit "Could not locate scripts directory ${scripts_dir}"
        fi
    fi
fi

# Debug output
if [[ ${debug} -eq 1 && ${no_pack} -eq 0 ]]; then
    echo "      App: ${app_name}"
    echo "Bundle ID: ${bundle_id}"
    echo "  Version: ${app_version}"
    echo "     Path: ${app_dir}/build/${app_name}"
    echo "      PKG: ${app_dir}/build/${app_name}-${app_version}.pkg"
    if [[ ${add_scripts} -eq 1 ]]; then
        echo "  Scripts: ${scripts_dir}"
    fi
fi

# Build the package
echo "Building ${app_name}... "
if [[ ${debug} -eq 1 ]]; then
    xcodebuild clean install -target "${app_name}" || show_error_then_exit "Could not build app"
else
    xcodebuild -quiet clean install -target "${app_name}" || show_error_then_exit "Could not build app"
fi

# FROM 4.0.1
# Exit if no package is required
if [[ ${no_pack} -eq 1 ]]; then
    echo "Binary compiled to ${app_dir}/build/pkgroot/usr/local/bin/${app_name}"
    exit 0
fi

# Build and sign the package
echo "Making and signing the package... "
if [[ ${add_scripts} -eq 1 ]]; then
    success=$(pkgbuild --scripts "${scripts_dir}" --root build/pkgroot --identifier "${bundle_id}.pkg" --install-location "/" --sign "${cert_name}" --version "${app_version}" "build/${app_name}-${app_version}.pkg")
else
    success=$(pkgbuild --root build/pkgroot --identifier "${bundle_id}.pkg" --install-location "/" --sign "${cert_name}" --version "${app_version}" "build/${app_name}-${app_version}.pkg")
fi

if [[ -z "${success}" ]]; then
    show_error_then_exit "Failed to make the package"
fi

# Notarize the package by getting the app's bundle ID then calling notarytool
# NOTE altool is now deprecated
echo "Requesting package notarization... this may take some time "
n_time=$(date +%s)
response=$(xcrun notarytool submit "build/${app_name}-${app_version}.pkg" --wait -p ${profile_name})

# Get the notarization job ID from the response
e_time=$(date +%s)
job_id_line=$(grep -m 1 '  id:' < <(echo -e "${response}"))
job_id=$(echo "${job_id_line}" | cut -d ":" -s -f 2 | cut -d " " -f 2)

if [[ ${debug} -eq  1 ]]; then
    n_time=$((e_time - n_time))
    echo "Notarization completed after ${n_time} seconds. Job ID: ${job_id}"
fi

# Get the notarization status from the response
status_line=$(grep -m 1 '  status:' < <(echo -e "${response}"))
status_result=$(echo "${status_line}" | cut -d ":" -s -f 2 | cut -d " " -f 2)

if [[ ${status_result} != "Accepted" ]]; then
    show_error_then_exit "Notarization failed with status q${status_result}"
fi

# Staple the notarization result
echo "Adding notarization to build/${app_name}-${app_version}.pkg "
success=$(xcrun stapler staple "build/${app_name}-${app_version}.pkg")
if [[ -z "${success}" ]]; then
    show_error_then_exit "Could not staple notarization to app"
fi

# Confirm stapling
echo "Checking notarization to build/${app_name}-${app_version}.pkg "
spctl --assess -vvv --type install "build/${app_name}-${app_version}.pkg"

# Clean up
echo "Moving package to desktop "
mv "build/${app_name}-${app_version}.pkg" "${HOME}/desktop/${app_name}-${app_version}.pkg"

if [[ -d "${app_dir}/manpage" ]]; then
    echo "Moving man page file to desktop "
    cp "${app_dir}/manpage/"* $HOME/desktop
fi

rm -rf "build"
exit 0

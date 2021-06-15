#!/bin/zsh

#
# packcli
#
# Command line tool release preparation script
#
# @author    Tony Smith
# @copyright 2021 Tony Smith
# @version   3.1.4
# @license   TBD
#


# Simple function to present help information
show_help() {
    echo -e "\npackcli -- create a signed and notarized app package\n"
    echo -e "Usage: packcli.zsh [OPTIONS]\n"
    echo "Options:"
    echo    "  -s / --source    - The location of the target project. Default: current directory."
    echo    "  -n / --name      - The target tool's name. If no name is supplied, packcli uses"
    echo    "                     the name of the source project."
    echo    "  -b / --bundleid  - The target tool's bundle ID. This is not optional."
    echo    "  -v / --version   - The target tool's version. Default: 1.0.0."
    echo    "  -a / --add       - Add scripts from the project's pkgscripts directory."
    echo    "  -u / --user      - Your Apple Developer username."
    echo    "  -c / --cert      - Your Apple Developer Installer certificate name, eg."
    echo    "                     'Developer ID Installer: Fred Bloggs (ABCDEF1234)'."
    echo    "  -d / --debug     - Enable extra debugging."
    echo -e "  -h / --help      - This help page.\n"
}


# Exit script on fail
set -e

# Setup
app_name="Untitled"
app_source="$PWD"
app_version="1.0.0"
notify_status="zzz"
bundle_id="zzz"
user_name="none"
cert_name="none"
typeset -i is_arg=0
typeset -i add_scripts=0
typeset -i debug=0
typeset -i poll_delay=30

# Process the command line arguments
for var in "$@"; do
    if [[ $is_arg -eq 0 ]]; then
        var=${var:l}
        if [[ "$var" = "-h" || "$var" = "--help" ]]; then
            # Display help then bail
            show_help
            exit 0
        elif [[ "$var" = "-a" || "$var" = "--add" ]]; then
            add_scripts=1
        elif [[ "$var" = "-d" || "$var" = "--debug" ]]; then
            debug=1
        elif [[ "$var" = "-n" || "$var" = "--name" ]]; then
            # Next arg should be the cli tool name, eg. 'pdfmaker'
            is_arg=2
        elif [[ "$var" = "-s" || "$var" = "--source" ]]; then
            # Next arg should be the project folder, eg. '$GIT/pdfmaker'
            is_arg=3
        elif [[ "$var" = "-b" || "$var" = "--bundleid" ]]; then
            # Next arg should be the cli tool bundle ID, eg. 'com.bps.pdfmaker'
            is_arg=4
        elif [[ "$var" = "-v" || "$var" = "--version" ]]; then
            # Next arg should be the cli tool's version string
            is_arg=5
        elif [[ "$var" = "-u" || "$var" = "--user" ]]; then
            # Next arg should be the username
            is_arg=6
        elif [[ "$var" = "-c" || "$var" = "--cert" ]]; then
            # Next arg should be the cert name
            is_arg=7
        else
            # An unknown arg included: warn and bail
            echo "[ERROR] Unknown option ($var) included"
            exit 1
        fi
    else
        if [[ $is_arg -eq 2 ]]; then
            # Set the app name
            app_name="$var"
        elif [[ $is_arg -eq 3 ]]; then
            # Set the source
            app_source="$var"
        elif [[ $is_arg -eq 4 ]]; then
            # Set the source
            bundle_id="$var"
        elif [[ $is_arg -eq 5 ]]; then
            # Set the source
            app_version="$var"
        elif [[ $is_arg -eq 6 ]]; then
            # Set the source
            user_name="$var"
        elif [[ $is_arg -eq 7 ]]; then
            # Set the source
            cert_name="$var"
        else
            # An arg does not have a value: warn and bail
            echo "[ERROR] Option selected without expected parameter: $is_arg"
            exit 1
        fi

        is_arg=0
    fi
done

# Check input before we proceed
if [[ "$bundle_id" = "zzz" ]]; then
    echo "ERROR: No bundle ID provided"
    exit 1
fi

# FROM 3.0.0
# Confirm we have a username
if [[ "$user_name" = "none" ]]; then
    echo "[ERROR] You must provide a username with the -u/--user switch"
    exit 1
fi

# FROM 3.1.0
# Confirm we have a cert name
if [[ "$cert_name" = "none" ]]; then
    echo "[ERROR] You must provide a certificate ID with the -c/--cert switch"
    exit 1
fi

# Check for script additions
extra=""
if [[ $add_scripts -eq 1 ]]; then
    if [[ ! -e "$app_source/pkgscripts" ]]; then
        echo "[ERROR] \'pkgscripts\' directory missing from $app_source "
        exit 1
    fi

    extra="--scripts $app_source/pkgscripts"
fi

# Debug output
if [[ $debug -eq 1 ]]; then
    echo "      App: $app_name"
    echo "Bundle ID: $bundle_id"
    echo "  Version: $app_version"
    echo "     Path: $app_source/build/$app_name"
    echo "      PKG: $app_source/build/$app_name-$app_version.pkg"
fi

# Build the package
cd "$app_source"  || exit 1
echo "Building $app_name... "
success=$(xcodebuild clean install)
if [[ -z "$success" ]]; then
    exit 1
fi

# Build and sign the package
echo "Making and signing the package... "
success=$(pkgbuild $extra --root build/pkgroot --identifier "$bundle_id.pkg" --install-location "/" --sign "$cert_name" --version "$app_version" "build/$app_name-$app_version.pkg")
if [[ -z "$success" ]]; then
    echo "[Error] packcli"
    exit 1
fi

# Notarize the package by getting the app's bundle ID then calling altool
# See https://developer.apple.com/documentation/xcode/notarizing_your_app_before_distribution/customizing_the_notarization_workflow#3087734
echo "Requesting package notarization... this may take some time "
n_time=$(date +%s)
response=$(xcrun altool --notarize-app --file "build/$app_name-$app_version.pkg" --primary-bundle-id "$bundle_id.pkg" --username "$user_name" --password "@keychain:AC_PASSWORD")

# Check the altool response for errors, and bail if there are any
if [[ "$response" == *"Error:"* ]]; then
    echo "[Error] $response"
    exit 1
fi

# Get the notarization job ID from the response
e_time=$(date +%s)
job_id_line=$(grep 'RequestUUID =' < <(echo -e "$response"))
job_id=$(echo "$job_id_line" | cut -d "=" -s -f 2 | cut -d " " -f 2)

if [[ $debug -eq  1 ]]; then
    n_time=$((e_time - n_time))
    echo "Notarization upload completed after $n_time seconds. Notarization job ID: $job_id"
fi

# Repeatedly check the notarization status until the job succeeds or fails
# TODO Add a timeout and error check
echo "Polling for notarization... "
n_time=$(date +%s)
while true; do
    # Request a notarization job status
    # See https://developer.apple.com/documentation/xcode/notarizing_your_app_before_distribution/customizing_the_notarization_workflow#3087732
    response=$(xcrun altool --notarization-info "$job_id" --username "$user_name" --password "@keychain:AC_PASSWORD")

    # Check the altool response for errors, and bail if there are any
    if [[ "$response" == *"Error:"* ]]; then
        echo "[Error] $response "
        exit 1
    fi

    # Parse the response to get the job status
    status_line=$(grep '\s*Status:' < <(echo -e "$response"))
    notify_status=$(echo "$status_line" | cut -d ":" -s -f 2)

    if [ $debug -eq  1 ]; then
        echo "Status: $notify_status"
        # NOTE 'status' has an initial space
    fi

    # Break out of the poll loop on notarization success
    if [[ "$notify_status" = "success" || "$notify_status" = " success" ]]; then
        break
    fi

    # Exit the app on notarization failure
    if [[ "$notify_status" = "invalid" || "$notify_status" = " invalid" ]]; then
        echo "[ERROR] Unable to notarize build/$app_name-$app_version.pkg -- outputting response: "
        echo "$response"
        exit 1
    fi

    # Pause for 'pollDelay' then continue the poll loop
    sleep "$poll_delay"
done

e_time=$(date +%s)

if [[ $debug -eq  1 ]]; then
    n_time=$((e_time - n_time))
    echo "Polling completed after $n_time seconds."
fi

echo "Adding notarization to build/$app_name-$app_version.pkg "
success=$(xcrun stapler staple "build/$app_name-$app_version.pkg")
if [[ -z "$success" ]]; then
    exit 1
fi

# Confirm stapling
echo "Checking notarization to build/$app_name-$app_version.pkg "
spctl --assess -vvv --type install "build/$app_name-$app_version.pkg"

echo "Moving package to desktop "
mv "build/$app_name-$app_version.pkg" "$HOME/desktop/$app_name-$app_version.pkg"
rm -rf "build"
exit 0

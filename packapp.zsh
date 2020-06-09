#!/bin/zsh

#
# packapp
#
# App release preparation script
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   4.0.1
# @license   TBD
#


# Simple function to present help information
show_help() {
    echo -e "\npackapp -- create a signed and notarized app package\n"
    echo "This script requires an Apple Developer Account. You will need to set up an app key"
    echo "for the Apple ID linked to your Developer Account, and to have saved this key in your"
    echo "Mac's keychain under the ID 'AC_PASSWORD'. Pass the keychain item's account name to"
    echo "the script as your username."
    echo -e "\nUsage: packapp [OPTIONS] <app-path>\n"
    echo "Options:"
    echo "  -s / --scripts [path]  - Add pre- and/or post-install scripts to the package."
    echo "  -u / --user            - Your username."
    echo "  -c / --cert            - Your Developer ID Installer certificate descriptor, eg."
    echo "  -c / --cert            - 'Developer ID Installer: Fred Bloggs (ABCDEF1234)'"
    echo "  -v / --verbose         - Show extra informational output."
    echo -e "  -h / --help            - This help page.\n"
    echo "Example:"
    echo "  packapp.zsh -u my_keychain_un -c \"Developer ID Installer: Fred Bloggs (ABCDEF1234)\" \"\$HOME/my app.app\""
    echo
}


# Exit script on fail
set -e
setopt nomatch

# Setup
app_name="none"
app_source="$PWD"
script_source="$PWD"
path_arg="zzz"
is_arg=0
add_scripts=0
debug=0
poll_delay=30
poll_status="zzz"
uname="none"
cert="none"


# Process the command line arguments
for var in "$@"; do
    if [ $is_arg -eq 0 ]; then
        var=${var:l}
        if [[ "$var" = "-h" || "$var" = "--help" ]]; then
            # Display help then bail
            show_help
            exit 0
        elif [[ "$var" = "-v" || "$var" = "--verbose" ]]; then
            # Enable verbose mode
            debug=1
        elif [[ "$var" = "-s" || "$var" = "--scripts" ]]; then
            # Next arg should be the script directory path
            add_scripts=1
            is_arg=1
        elif [[ "$var" = "-u" || "$var" = "--user" ]]; then
            # Get the username
            is_arg=2
        elif [[ "$var" = "-c" || "$var" = "--cert" ]]; then
            # Get the Developer ID Installer cert name
            is_arg=3
        elif [ "${var:0:1}" = "-" ]; then
            # An unknown arg included: warn and bail
            echo "[ERROR] Unknown option ($var) included"
            exit 1
        else
            # Assume this is the app path
            path_arg="$var"
        fi
    else
        if [ "${var:0:1}" = "-" ]; then
            echo "[ERROR] Missing argument"
            exit 1
        elif [ $is_arg -eq 1 ]; then
            # Set the script source
            script_source="$var"
        elif [ $is_arg -eq 2 ]; then
            # Set the username
            uname="$var"
        elif [ $is_arg -eq 3 ]; then
            # Set the Developer ID Installer cert
            cert="$var"
        else
            # An arg does not have a value: warn and bail
            echo "[ERROR] Option selected without expected argument"
            exit 1
        fi

        is_arg=0
    fi
done

# Parse any specifiec app path
while true; do
    if [ $path_arg != "zzz" ]; then
        app_name=${path_arg:t}
        if [ $app_name != $path_arg ]; then
            # The argument is a path, so extract the directory
            app_source=${path_arg:h}
        fi

        extension=${app_name:e}

        if [ -n "$extension" ]; then
            # The supplied name has an extension...
            if [ "$extension" != "app" ]; then
                # ...but it's not .app, so bail
                echo "[ERROR] Selected file is not an app (it's a .$extension)"
                exit 1
            else
                # Remove the extension from the filename
                app_name=${app_name:r}
                break
            fi
        else
            # The supplied name lacks an extenion... is it file or dir?
            if [ -d $path_arg ]; then
                # It's a directory, so use the full path
                app_source=$path_arg
                path_arg="zzz"
            else
                break
            fi
        fi
    else
        # No app name specified, so check for a .app file in source directory
        # Set the following option to pevent an error on empty directories
        setopt NULL_GLOB
        typeset -i app_count=0
        for file in ${app_source}/* ; do
            # Only process directories (.app is a directory)
            if [ -d $file ]; then
                # Get the extension
                extension=${file:t:e}

                # If it's a .app, use it as the app name, eg. 'MNU'
                if [[ $extension = "app" ]]; then
                    app_name=${file:t:r}
                    ((app_count += 1))
                fi
            fi
        done
        # Put zsh back to where it was
        unsetopt NULL_GLOB

        # Check, report and bail on multiple .app matches
        if [ $app_count -gt 1 ]; then
            echo "[ERROR] Multiple apps found in $app_source. Please specify the one you want to package"
            exit 1
        fi

        # Check, report and bail on no .app matches
        if [ $app_count -eq 0 ]; then
            echo "[ERROR] No apps found in $app_source "
            exit 1
        fi

        break
    fi
done

# Set the filename
app_filename="$app_name.app"

# FROM 3.0.0
# Confirm we have a username...
if [ $uname = "none" ]; then
    echo "[ERROR] You must provide a username with the -u/--user switch"
    exit 1
fi

# ...and a cert
if [ $cert = "none" ]; then
    echo "[ERROR] You must provide a Developer ID Installer with the -c/--cert switch"
    exit 1
fi

# Confirm the specified app is present in the source directory
if [ ! -e "$app_source/$app_filename" ]; then
    echo "[ERROR] App '$app_name' not found in '$app_source'"
    exit 1
fi

# Check for script additions
extra=""
if [ $add_scripts -eq 1 ]; then
    if [ ! -e "$script_source" ]; then
        echo "[ERROR] '$script_source' scripts directory missing "
        exit 1
    fi

    extra="--scripts $script_source"
fi

# Finally, output the data we have parsed
if [ $debug -eq 1 ]; then
    echo "App Path: $app_source"
    echo "App Name: $app_filename"
    echo "Dev. ID Cert: $cert"

    if [ -n "$extra" ]; then
        echo " Scripts: $script_source"
    fi

    # Check the app to be packaged
    spctl -a -v ${app_source}/${app_filename}
fi

# Build the package
echo "Making and signing package... "
bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_source/$app_filename/Contents/Info.plist")
setopt
success=$(pkgbuild ${=extra} --identifier "$bundle_id.pkg" --install-location "/Applications" --sign "$cert" --component "$app_source/$app_filename" "$app_source/$app_name.pkg")
if [ -z "$success" ]; then
    exit 1
fi

# Notarize the package by getting the app's bundle ID then calling altool
# See https://developer.apple.com/documentation/xcode/notarizing_your_app_before_distribution/customizing_the_notarization_workflow#3087734
echo "Uploading package for notarization... this may take some time "
n_time=$(date +%s)
response=$(xcrun altool --notarize-app --file "$app_source/$app_name.pkg" --primary-bundle-id "$bundle_id" --username "$uname" --password "@keychain:AC_PASSWORD")

# Check the altool response for errors, and bail if there are any
if [[ "$response" == *"Error:"* ]]; then
    echo "[Error] $response"
    exit 1
fi

# Get the notarization job ID from the response
e_time=$(date +%s)
job_id_line=$(grep 'RequestUUID =' < <(echo -e "$response"))
job_id=$(echo "$job_id_line" | cut -d "=" -s -f 2 | cut -d " " -f 2)

if [ $debug -eq  1 ]; then
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
    response=$(xcrun altool --notarization-info "$job_id" -u "$uname" -p "@keychain:AC_PASSWORD")

    # Check the altool response for errors, and bail if there are any
    if [[ -z "$response" ]]; then
        echo "[Error] $response "
        exit 1
    fi

    # Parse the response to get the job status
    status_line=$(grep '\s*Status:' < <(echo -e "$response"))
    poll_status=$(echo "$status_line" | cut -d ":" -s -f 2)

    if [ $debug -eq  1 ]; then
        echo "Status: $poll_status"
    fi

    # Break out of the poll loop on notarization success
    if [[ "$poll_status" = "success" || "$poll_status" = " success" ]]; then
        break
    fi

    # Exit the app on notarization failure
    if [[ "$poll_status" = "invalid" || "$poll_status" = " invalid" ]]; then
        echo "[ERROR] Unable to notarize $app_name.pkg -- outputting response: "
        echo "$response"
        exit 1
    fi

    # Pause for 'pollDelay' then continue the poll loop
    sleep "$poll_delay"
done

e_time=$(date +%s)

if [ $debug -eq  1 ]; then
    n_time=$((e_time - n_time))
    echo "Polling completed after $n_time seconds."
fi

echo "Adding notarization to $app_name.pkg "
success=$(xcrun stapler staple "$app_source/$app_name.pkg")
if [ -z "$success" ]; then
    exit 1
fi

# Confirm stapling
if [ $debug -eq 1 ]; then
    spctl -a -v --type install "$app_source/$app_name.pkg"
fi

echo "Done -- you can now add $app_name.pkg to a .dmg file "
exit 0

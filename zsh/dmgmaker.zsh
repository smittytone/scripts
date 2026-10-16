#!/bin/zsh

#
# dmgmaker
#
# App release preparation script
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   3.0.0
# @license   MIT
#

# FROM 2.0.0
# Simple function to present help information
show_help() {
    cat << EOF
dmgmaker -- create a dmg for app distribution

Usage: dmgmaker.zsh [OPTIONS]

Options:
    -s / --source       The location of the target .app or .pkg file.
    -n / --name         The DMG volume name.
                        Default: the app/pkg name.
    -d / --destination  The location and name of the generated .dmg file.
                        Default: current directory plus app/pkg name.
    -l / --link         Include a link to the Applications folder.
    -h / --help         This help page.

    Example:
        /devscripts/dmgmaker.zsh -p my_pkg.pkg -v 'My App 1.0.0' -f ~/downloads/my_app_1_0_0.dmg"

EOF
}

# Emit error then exit
show_error_then_exit() {
    printf "⛔️ $1\n" 1>&2
    exit 1
}


app_path=""
final_dmg_path=""
vol_mount_name=""
base_dmg_path="$HOME/base.sparsebundle"
add_apps_link=0


# FROM 2.0.0
# Process the command line arguments
arg_is_value=0
for arg in "$@"; do
    if [[ ${arg_is_value} -eq 0 ]]; then
        var=${arg:l}
        if [[ "${var}" = "-h" || "${var}" = "--help" ]]; then
            # Display help then bail
            show_help
            exit 0
        elif [[ "${var}" = "-s" || "${var}" = "--source" ]]; then
            arg_is_value=1
        elif [[ "${var}" = "-n" || "${var}" = "--name" ]]; then
            arg_is_value=2
        elif [[ "${var}" = "-d" || "${var}" = "--destination" ]]; then
            arg_is_value=3
        elif [[ "${var}" = "-l" || "${var}" = "--link" ]]; then
            add_apps_link=1
        else
            # An unknown arg included: warn and bail
            show_error_then_exit "Unknown option (${arg}) included"
        fi
    else
        case ${arg_is_value} in
            1) app_path="${arg}" ;;
            2) vol_mount_name="${arg}" ;;
            3) final_dmg_path="${arg}" ;;
            *) show_error "Option selected without expected parameter: ${arg_is_value}" ;;
        esac
        arg_is_value=0
    fi
done

# Check the input -- a path to the app is mandatory
if [ -z "${app_path}" ]; then
    show_error_then_exit "No app specified"
fi

app_ext=${app_path:t:e}
app_name=${app_path:t:r}

# The name of final DMG is optional:
# it will be based on the app name if not specified
if [ -z "${final_dmg_path}" ]; then
    final_dmg_path="$(pwd)/${app_name}.dmg"
fi

# Set the DMG mounted volume name to that of the app
if [ -z "${vol_mount_name}" ]; then
    vol_mount_name="${app_name}"
fi

printf "💿 Volume name:  ${vol_mount_name}\n"
printf "📁 Source build: ${base_dmg_path}\n"
printf "📁 Destination:  ${final_dmg_path}\n\n"

# Make a 100MB DMG, mount it, copy the app, make a link to /Applications, dismount the volume, compress the DMG
printf "🏗️ Assembling the DMG file...\n"
# hdiutil create "${base_dmg_path}" -size 100MB -type SPARSEBUNDLE -fs HFS+J -volname "${vol_mount_name}" -quiet
diskutil quiet image create blank -s 100MB --fs APFS --volname "${vol_mount_name}" "${base_dmg_path}"
#hdiutil attach "${base_dmg_path}" -quiet
diskutil quiet image attach "${base_dmg_path}"

# Copy the notarized file
printf "🚚 Moving files to the DMG...\n"
# Add a link to the Applications folder
if [ "${add_apps_link}" -eq 1 ]; then
    printf "📁 Adding link to /Applications...\n"
    ln -s "/Applications" "/Volumes/${vol_mount_name}/Applications"
fi

if cp -RH "${app_path}" "/Volumes/${vol_mount_name}/" ; then
    printf "🗜️ Re-sizing the DMG...\n"
    #hdiutil detach "/Volumes/${vol_mount_name}" -quiet
    diskutil quiet eject "/Volumes/${vol_mount_name}"
    #hdiutil convert "${base_dmg_path}" -format ULMO -imagekey 9 -o "${final_dmg_path}" -quiet
    diskutil quiet image create from -f ULFO "${base_dmg_path}" "${final_dmg_path}" &> /dev/null
    printf "🧽 Cleaning up...\n\n"
    rm -rf "${base_dmg_path}"
    sha=$(shasum -a 256 "${final_dmg_path}")
    sha=$(echo "${sha}" | cut -f 1 -d ' ')
    printf "🔒 DMG SHA-256: %s\n" "${sha}"
else
    show_error_then_exit "Could not copy the app to the DMG"
fi

exit 0

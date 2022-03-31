#!/bin/zsh

# binstall.zsh
#
# Install key scripts into /usr/local/bin or alternative directory.
#
# NOTE Depends upon $GIT/dotfiles/Mac/keyscripts and
#      $GIT/scripts as source of script list and scripts,
#      respectively. And $GIT must be set.
#
# @version   1.6.0
# @author    Tony Smith (@smittytone)
# @copyright 2022
# @licence   MIT

app_version="1.6.0"
bin_dir=/usr/local/bin
source_file="$GIT/dotfiles/Mac/keyscripts"
scripts_dir="$GIT/scripts"
repos=()
states=()
versions=()
typeset -i update_count=0
typeset -i name_max=0
typeset -i ver_max=7
typeset -i do_show=1
typeset -i do_list=0
typeset -i source_changed=0
typeset -i scripts_changed=0
typeset -i bin_changed=0

# FROM 1.5.0
# Colours
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7 && tput bold)
normal=$(tput sgr0)
bar="${white}|${normal}"

# FROM 1.1.0
# Display the version if requested
get_version() {
    script=$(cat "${1}")
    result=$(grep '# @version' < <(echo -e "${script}"))
    result=$(tr -s " " < <(echo -e "${result}"))
    version=$(echo "${result}" | cut -d " " -s -f 3)
    repos+=(${1:t})
    versions+=(${version})

    if [[ "$2" == "N" ]]; then
        states+=("${green}Up to date${normal}")
    else
        states+=("${yellow}Updated   ${normal}")
        ((update_count++))
    fi

    # Set the version number and app name max column width
    if [[ ${#1:t} -gt ${name_max} ]] name_max=${#1:t}
    if [[ ${#version:t} -gt ${ver_max} ]] ver_max=${#version:t}
}

# FROM 1.3.0
# Print the main output table header
# FROM 1.4.1 -- span column three to max version string size,
#               pass in string lengths
print_header_main() {
    printf "${white}| %-*s | %-*s | %-10s |\n+-" ${1} Utility ${2} Version State
    print_mid ${1} ${2}
    printf "-+------------+${normal}\n"
}

# FROM 1.4.0
# Print the list output table header
# FROM 1.4.1 -- pass in string lengths
print_header_list() {
    printf "${white}| %-*s | %-*s |\n+-" ${1} Utility ${2} Version
    print_mid ${1} ${2}
    printf "-+${normal}\n"
}

print_mid() {
    printf "-%.0s" {0..${1}}
    printf "+"
    printf "-%.0s" {0..${2}}
}

print_err_and_exit() {
    echo "[ERROR] ${1}"
    exit 1
}

# FROM 1.6.0
print_message() {
    if [[ $do_show -eq 1 ]] echo "${1}"
}

show_version() {
    echo "binstall ${app_version}"
}
show_help() {
    echo
    show_version
    echo
    echo -e "Usage:\n  binstall [-l] [-q] [-v] [-h] [-t path/to/install/directory]\n"
    echo    "Options:"
    echo    "  -l / --list          Just list scripts current states"
    echo    "  -q / --quiet         Don't show script version and state information"
    echo    "  -v / --version       Display the utility's version and exit"
    echo    "  -t / --target [path] Specify an install directory. Default: /usr/local/bin"
    echo    "  -f / --file   [path] Specify a script-list file. Default: [git]/dotfiles/Mac/keyscripts"
    echo    "  -s / --source [path] Specify a script source directory. Default: [git]/scripts"
    echo    "  -h / --help          This help screen"
    echo
}

# Parse args
typeset -i arg_value=0
typeset -i arg_count=0
for arg in "$@"; do
    larg=${arg:l}
    if [[ $arg_value -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            print_err_and_exit "Missing value for ${args[((arg_value - 1))]}"
        fi

        # Set the appropriate internal value
        case $arg_value in
            1) bin_dir="${arg}" && bin_changed=1 ;;
            2) scripts_dir="${arg}" && scripts_changed=1 ;;
            3) source_file="${arg}" && source_changed=1 ;;
            *) print_err_and_exit "Unknown argument" ;;
        esac

        arg_value=0
    else
        if [[ "${larg}" == "-q" || "${larg}" == "--quiet" ]]; then
            do_show=0
        elif [[ "${larg}" == "-l" || "${larg}" == "--list" ]]; then
            do_list=1
        elif [[ "${larg}" == "-t" || "${larg}" == "--target" ]]; then
            arg_value=1
        elif [[ "${larg}" == "-s" || "${larg}" == "--scripts" ]]; then
            arg_value=2
        elif [[ "${larg}" == "-f" || "${larg}" == "--file" ]]; then
            arg_value=3
        elif [[ "${larg}" == "-h" || "${larg}" == "--help" ]]; then
            show_help
            exit 0
        elif [[ "${larg}" == "-v" || "${larg}" == "--version" ]]; then
            show_version
            exit 0
        fi
    fi

    ((arg_count++))
    if [[ $arg_count -eq $# && $arg_value -ne 0 ]]; then
        print_err_and_exit "Missing value for option ${arg}"
    fi
done

# FROM 1.5.0
# Check for incompatible flags
if [[ $do_list -eq 1 && $do_show -eq 0 ]]; then
    print_err_and_exit "Incompatable flags chosen: you can't list files quietly -- exiting"
fi

# Check for a bin directory and make if it's not there yet
if [[ ! -e "${bin_dir}" ]]; then
    mkdir -p "${bin_dir}" || print_err_and_exit "Could not create ${bin_dir} -- exiting"
fi

# FROM 1.6.0
# Messages
if [[ $bin_changed -ne 0 ]] print_message "Installation directory set to ${bin_dir}"
if [[ $source_changed -ne 0 ]] print_message "File list set to ${source_file}"
if [[ $scripts_changed -ne 0 ]] print_message "Scripts directory set to ${scripts_dir}"

# Load in the list of scripts
if [[ -e "${source_file}" ]]; then
    if [[ -e "${scripts_dir}" ]]; then
        # Read in each line of 'keyscripts', each of which
        # is the name of a script to copy, eg. 'update.zsh'
        while IFS= read -r line; do
            target_file="${bin_dir}/${line:t:r}"

            # FROM 1.4.0 -- Don't copy, just get the version,
            # if we're just listing files
            if [[ $do_list -eq 0 ]]; then
                # FROM 1.0.1 -- check of the source and target are different
                # FROM 1.0.2 -- don't block install of uninstalled scripts
                diff_result="DO"

                if [[ -e ${target_file} ]]; then
                    diff_result=$(diff ${target_file} "${scripts_dir}/${line}")
                fi

                # FROM 1.0.1
                # Only copy if the file is different
                if [[ -n ${diff_result} ]]; then
                    cp "${scripts_dir}/${line}" ${target_file}
                    get_version ${target_file} Y
                else
                    get_version ${target_file} N
                fi

                # Make the file executable
                chmod +x ${target_file}
            else
                # Just get the version for each source file
                if [[ -e $target_file ]]; then
                    get_version $target_file N
                fi
            fi
        done < "${source_file}"
    else
        print_err_and_exit "'${scripts_dir}' does not exist... exiting"
    fi
else
    print_err_and_exit "'${source_file}' does not exist... exiting"
fi

# Display the output
# FROM 1.3.0 -- as a table
# FROM 1.4.0 -- with an alternative version-only list
# FROM 1.4.1 -- pass string lengths to function calls
if [[ $do_show -eq 1 ]]; then
    if [[ $do_list -eq 0 ]]; then
        print_header_main ${name_max} ${ver_max}
        format_string="${bar} %-*s ${bar} %-*s ${bar} %-9s ${bar} \n"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            printf ${format_string} ${name_max} ${repos[i]} ${ver_max} ${versions[i]} ${states[i]}
        done
    else
        print_header_list ${name_max} ${ver_max}
        format_string="${bar} %-*s ${bar} %-*s ${bar}\n"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            printf ${format_string} ${name_max} ${repos[i]} ${ver_max} ${versions[i]}
        done
    fi
else
    case "$update_count" in
        0) echo "No scripts updated" ;;
        1) echo "1 script updated" ;;
        *) echo "$update_count scripts updated" ;;
    esac
fi
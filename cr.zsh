#!/usr/bin/env zsh

#
# cover rename
#
# Process comic cover names
#
# @author    Tony Smith
# @copyright 2023, Tony Smith
# @version   1.0.0
# @license   MIT
#


declare -A months
months=([january]=01 [february]=02 [march]=03 [april]=04 [may]=05 [june]=06 [july]=07 [august]=08 [september]=09 [october]=10 [november]=11 [december]=12)


# Get all the entries in the working directory
for file in ~+/*; do
    # Only process files
    if [ -f "${file}" ]; then
        # Get the extension
        fname=${file:t:r}
        extension=${file:t:e}
        extension=${extension:l}

        fyear=""
        fmonth=""
        fday=""
        fiss=""

        # Get the filename and add back the extension
        fiss=$(echo "${fname}" | cut -d " " -s -f 1)

        if [[ -n ${fiss} && ${fiss} != " " ]]; then
            fdate=$(echo "${fname}" | cut -d " " -s -f 2)
        else
            fdate=${fname}
        fi

        # Set $1 to anything to get the monthly version
        if [ -z $1 ]; then
            fyear=$(echo "${fdate}" | cut -d "-" -s -f 3)
            fyear="${fyear:0:-1}"

            fmonth=$(echo "${fdate}" | cut -d "-" -s -f 2)
            [ ${#fmonth} -eq 1 ] && fmonth="0${fmonth}"
            [ -z ${#fmonth}  ] && fmonth="xx"

            fday=$(echo "${fdate}" | cut -d "-" -s -f 1)
            fday=${fday:1}
            [ ${#fday} -eq 1 ] && fday="0${fday}"
            [ -z ${#fday}  ] && fday="xx"

            newfilename="${fyear}-${fmonth}-${fday}"
        else
            fmonth=$(echo "${fname}" | cut -d " " -s -f 2)
            fmonth="${fmonth:1}"
            fmonth=${fmonth:l}
            fmonth=${months[${fmonth}]}

            fyear=$(echo "${fname}" | cut -d " " -s -f 3)
            fyear=${fyear:0:-1}

            newfilename="${fyear}-${fmonth}"
        fi

        if [[ -n ${fiss} && ${fiss} != " " ]]; then
            [ ${#fiss} -eq 1 ] && fiss="00${fiss}"
            [ ${#fiss} -eq 2 ] && fiss="0${fiss}"
            newfilename="${newfilename} (${fiss})"
        else
            newfilename="${newfilename} (xxx)"
        fi

        newfilename="${newfilename}.${extension}"
        echo "${file:h}/${newfilename}"

        # Apply the change
        mv "${file}" "${file:h}/${newfilename}"
    fi
done

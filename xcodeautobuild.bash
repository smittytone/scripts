#!/bin/bash

# This script takes the build number from the release target plist, increments and then saves back

buildNum=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PRODUCT_SETTINGS_PATH}")
buildNum=$(($buildNum + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNum" "${PRODUCT_SETTINGS_PATH}"

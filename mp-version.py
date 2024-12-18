#!/usr/bin/env python3

#
# MicroPython Checker
#
# Print the latest version of MicroPython (https://micropython.org) available
#
# @author    Tony Smith
# @copyright 2024, Tony Smith
# @version   1.2.0
# @license   MIT
#
# @Pre-requisites: `requests` library [`pip3 install requests`]
#
# ΝΟΤΕS
#
# 1.2.0 - Inverts behaviour: previews must now be requested with --include-previews

import requests
import argparse
import sys


def compare(b, i):
    global highest
    if highest[i] > b[i]: return True
    if highest[i] < b[i]:
        highest = b
        return True
    return False


# semver index values
MAJOR = 0
MINOR = 1
PATCH = 2

# Versions
current = [0, 0, 0]
highest = [0, 0, 0]

# Get the current version as an arg
parser = argparse.ArgumentParser(description="Compare your current MicroPython version with the latest")
parser.add_argument("-v", "--version", metavar="x.y.z", type=str, help="A MicroPython version, eg. 1.16.1", required=False)
parser.add_argument("-i", "--include-previews", dest="ignore", action='store_false', help="Whether proview releases should be listed", required=False)
parser.set_defaults(ignore=True)
args = parser.parse_args()

# Check any parsed version
if args.version is not None:
    try:
        parts = args.version.split(".")
        if len(parts) > 3: throw
        if len(parts) == 3: current = [int(parts[0]), int(parts[1]), int(parts[2])]
        if len(parts) == 2: current = [int(parts[0]), int(parts[1]), 0]
        if len(parts) == 1: current = [int(parts[0]), 0, 0]
    except Exception as _:
        print("[ERROR] Could not process", args.version, "as a version number")
        sys.exit(1)

# Get the latest MicroPython version
url = "https://api.github.com/repos/micropython/micropython/tags"
headers = {"Accept": "application/vnd.github.v3+json"}
response = requests.get(url, headers=headers)
if response.status_code == 200:
    # Got data -- try and parse it
    try:
        data = response.json()
        # Get the latest MP version
        for item in data:
            if "name" in item:
                name = item["name"]
                if name[0] == "v": name = name[1:]
                parts = name.split(".")
                if len(parts) == 2: parts.append("0")
                is_preview = False
                if "preview" in parts[2]:
                    parts[2] = parts[2].split("-")[0]
                    is_preview = True
                version = [int(parts[0]), int(parts[1]), int(parts[2]), is_preview]
                parts = version

                if (is_preview and not args.ignore) or not is_preview:
                    if compare(version, MAJOR): continue
                    if compare(version, MINOR): continue
                    if highest[PATCH] < parts[PATCH]: highest = parts

        # Only compare version if one was supplied
        highest_version = str(highest[0]) + "." + str(highest[1]) + "." + str(highest[2])
        if highest[3]:
            highest_version += " (PREVIEW)"
        if args.version is not None:
            match = 0
            for i in range(0, 3):
                if highest[i] == current[i]: match += 1
            if match == 3:
                print("You have the current version of MicroPython", highest_version)
            else:
                print("Micropython current release is", highest_version, "-- you have", args.version)
        else:
            print("Micropython current release is", highest_version)
    except Exception as e:
        print("[ERROR] Could not parse response from GitHub", e)
else:
    print("[ERROR] Unable to access MicroPython repo")

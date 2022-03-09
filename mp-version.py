#!/usr/bin/env python3

#
# MicroPython Checker
#
# Create a baseline Raspberry Pi Pico C-language project
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.0.2
# @license   MIT
#
# @Pre-requisites: `requests` library [`pip3 install requests`]
#

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
current = [0,0,0]
highest = [0,0,0]

# Get the current version as an arg
parser = argparse.ArgumentParser(description="Compare your current MicroPython version with the latest")
parser.add_argument("-v", "--version", metavar="x.y.z", type=str, help="A MicroPython version, eg. 1.16.1", required=False)
args = parser.parse_args()

# Check any parsed version
if args.version != None:
    try:
        parts = args.version.split(".")
        if len(parts) > 3: throw
        if len(parts) == 3: current = [int(parts[0]),int(parts[1]),int(parts[2])]
        if len(parts) == 2: current = [int(parts[0]),int(parts[1]),0]
        if len(parts) == 1: current = [int(parts[0]),0,0]
    except Exception as e:
        print("ERROR -- could not process", args.version, "as a version number")
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
                version = [int(parts[0]), int(parts[1]), int(parts[2])]
                parts = version

                if compare(version, MAJOR): continue
                if compare(version, MINOR): continue
                if highest[PATCH] < parts[PATCH]: highest = parts

        # Only compare version if one was supplied
        highest_version = str(highest[0]) + "." + str(highest[1]) + "." + str(highest[2])
        if args.version != None:
            match = 0
            for i in range(0,3):
                if highest[i] == current[i]: match += 1
            if match == 3:
                print("You have the current version of MicroPython", highest_version)
            else:
                print("Micropython current release is", highest_version, "-- you have", args.version)
        else:
            print("Micropython current release is", highest_version)
    except Exception as e:
        print("ERROR -- could not parse response from GitHub", e)
else:
    print("ERROR -- unable to access MicroPython repo")
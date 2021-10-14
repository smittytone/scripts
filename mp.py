#!/usr/bin/env python3

"""
MicroPython Checker 1.0.0
=========================

Copyright © 2021, Tony Smith (@smittytone)
License: MIT

Pre-requisites:
1. `requests` library -- `pip3 install requests`
"""

import requests
import sys

# Get the latest MicroPython version
url = "https://api.github.com/repos/micropython/micropython/tags"
headers = {"Accept": "application/vnd.github.v3+json"}
resp = requests.get(url, headers=headers)

if resp.status_code == 200:
    # Got date -- try and parse it
    data = ""
    latest = [0,0,0]
    try:
        data = resp.json()
        for item in data:
            if "name" in item:
                name = item["name"]
                if name[0] == "v": name = name[1:]
                parts = name.split(".")
                if len(parts) == 2: parts.append("0")
                version = [int(parts[0]), int(parts[1]), int(parts[2])]

                if latest[0] > version[0]: continue
                if latest[0] < version[0]:
                    latest = version
                    continue

                if latest[1] > version[1]: continue
                if latest[1] < version[1]:
                    latest = version
                    continue

                if latest[2] < parts[2]: latest = parts

        new_version = str(latest[0]) + "." + str(latest[1]) + "." + str(latest[2])
        print("Micropython current release is", new_version)
    except Exception as e:
        print("Error -- could not parse response from GitHub")
else:
    print("ERROR -- unable to access MicroPython repo")
#!/usr/bin/zsh

#
# Update Git libs
#
# Wraps Python virtual envronment stuff
# as mandated by Debian Bookworm
# see https://www.raspberrypi.com/documentation/computers/os.html#python-on-raspberry-pi
# 
# @author Tony Smith (@smittytone)
# @copyight 2023, Tony Smith
# @version 1.0.0
#
# This script ssumes you have set up a user-level virtual environment 
# using the following commands:
#
# ```
# python -m venv ~/.env`
# source ~/.env/bin/activate
# pip install gitup
# deactivate
# ```
# 

source ~/.env/bin/activate
gitup $GIT
deactivate

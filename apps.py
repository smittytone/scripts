#!/usr/bin/env python3

import os
import sys
import json
import requests
from requests.auth import HTTPBasicAuth
from datetime import datetime, timedelta

do_list_only = False
app_list = None
apps_to_delete = []
deployed_app = ""
api_url = "https://microvisor.twilio.com/v1/"
auth = HTTPBasicAuth(os.environ["TWILIO_ACCOUNT_SID"], os.environ["TWILIO_AUTH_TOKEN"])

if len(sys.argv) > 1:
  for index, item in enumerate(sys.argv):
    if item.lower() in ("-h", "--help"):
      print("Usage:   apps [--list]")
      print("Options: -l / --list   List but do not delete stale apps.")
      print("Stale apps are those more that 24 hours old. Stale apps")
      print("that are still assigned to a device will not be deleted")
      sys.exit()
    if item.lower() in ("-l", "--list"):
      do_list_only = True

print("Listing your Microvisor applications...")
date_now = datetime.now()
resp = requests.get(api_url + "Apps?PageSize=200", auth=auth)
if resp.status_code == 200:
  try:
    app_list = resp.json()
    if "apps" in app_list:
      for app in app_list["apps"]:
        sid = app["sid"]
        name = app["unique_name"]
        date_then = datetime.strptime(app["date_created"], '%Y-%m-%dT%H:%M:%SZ')
        if date_now - date_then >= timedelta(days=1):
          apps_to_delete.append(sid)
          sid = name if name else sid
          print(sid, "STALE")
        else:
          print(sid, "OK")
  except Exception as e:
    print("[ERROR] Could not parse response from Twilio", e)
else:
  print("[ERROR] Unable to access your apps")

if do_list_only:
  sys.exit()

if len(apps_to_delete) > 0:
  print("Deleting",len(apps_to_delete),"stale apps...")
  resp = requests.get(api_url + "Devices?PageSize=200", auth=auth)
  devices = None
  if resp.status_code == 200:
    try:
      dev_list = resp.json()
      if "devices" in dev_list:
        devices = dev_list["devices"]
    except Exception as e:
      pass

  for sid in apps_to_delete:
    resp = requests.delete(api_url + "Apps/" + sid, auth=auth)
    if resp.status_code == 204:
      print(sid, "DELETED")
    elif resp.status_code == 400:
      if devices:
        for device in devices:
          if device["app"]["target_sid"] == sid:
            deployed_app = sid
            break
      print(sid, "NOT DELETED (DEPLOYED TO DEVICE", (deployed_app if deployed_app else "UNKNOWN") + ")")
    else:
      print(sid, "NOT DELETED (CODE: " + str(resp.status_code) + ")")

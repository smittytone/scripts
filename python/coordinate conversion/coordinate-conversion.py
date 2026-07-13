#!/usr/bin/env python3

import re
import json
import simplekml
from os import path
from pathlib import Path

def dms_to_decimal(dms: str) -> str:
    """
    Convert a DMS (degrees, minutes, seconds) coordinate string to a
    decimal degrees float.

    Accepts a wide range of formats, e.g.:
        "36°24'32.9\"N"
        '36°24\'32.9"N'
        "36° 24' 32.9\" N"
        "36d24m32.9sN"
        "36 24 32.9 S"
        "51°30'26\"N"
        "-33°51'54\""        (negative for S/W, no hemisphere letter)
        "122°25'9.6\"W"

    Returns a signed float where S and W are negative.
    """
    pattern = re.compile(
        r"""
        \s*
        (?P<sign>[-+])?                      # optional leading sign
        (?P<deg>\d+(?:\.\d+)?)               # degrees (may be fractional)
        [°d\s]+                              # degree symbol, 'd', or whitespace
        (?:
            (?P<min>\d+(?:\.\d+)?)           # minutes (optional)
            ['\u2019m\s]+                    # minute symbol, 'm', or whitespace
        )?
        (?:
            (?P<sec>\d+(?:\.\d+)?)           # seconds (optional)
            ["\u201d\u2033s\s]*              # second symbol, 's', or whitespace
        )?
        (?P<hemi>[NSEWnsew])?                # optional hemisphere letter
        \s*$
        """,
        re.VERBOSE,
    )

    m = pattern.match(dms.strip())
    if not m:
        raise ValueError(f"Unrecognised DMS format: {dms!r}")

    deg  = float(m.group("deg"))
    mins = float(m.group("min") or 0)
    secs = float(m.group("sec") or 0)
    hemi = (m.group("hemi") or "").upper()
    sign = m.group("sign")

    if mins >= 60:
        raise ValueError(f"Minutes out of range (0–59): {mins}")
    if secs >= 60:
        raise ValueError(f"Seconds out of range (0–59): {secs}")

    decimal = deg + mins / 60 + secs / 3600

    # South and West are negative; an explicit '-' sign also negates
    if hemi in ("S", "W") or sign == "-":
        decimal = -decimal

    return f"{decimal:.6f}"


file_data = {"sites":[]}
features = []

with open("/Users/smitty/Desktop/sites.txt", 'r') as file:
    count = 0
    place = 1
    ref_lat = ""
    ref_lng = ""
    for line in file:
        if count % 2 == 0:
            # Even line, map data
            ref_parts = line.split(" ")
            if len(ref_parts) == 2:
                try:
                    ref_lat = dms_to_decimal(ref_parts[0])
                    ref_lng = dms_to_decimal(ref_parts[1])
                except ValueError as err:
                    print("[ERROR]",err)
            else:
                print("Bad co-ordinate:",count,line)
        else:
            name = line.rstrip()
            print(place,name,"@",ref_lat,ref_lng)
            file_data["sites"].append({"name":name,"location":{"lat":ref_lat,"lon":ref_lng}})
            place += 1

            feature = {
                "type": "Feature",
                "geometry": {"type": "Point", "coordinates": [ref_lng, ref_lat]},
                "properties": {
                    "name": name
                },
            }
            features.append(feature)
        count += 1

# Save the GeoJson
geojson = {"type": "FeatureCollection", "features": features}
out_path = Path("/Users/smitty/Desktop/sites.json")
with open(out_path, "w", newline="") as f:
    f.write(json.dumps(geojson))

# Save the KML
kml = simplekml.Kml()
style = simplekml.Style()
style.iconstyle.color = "FF0681BD"
out_path = Path("/Users/smitty/Desktop/sites.kml")
for feature in features:
    point = kml.newpoint(
        name=feature["properties"]["name"],
        description=feature["properties"]["name"],
        coords=[
            (
                feature["geometry"]["coordinates"][0],
                feature["geometry"]["coordinates"][1],
            )
        ],
    )
    point.style = style
kml.save(out_path)

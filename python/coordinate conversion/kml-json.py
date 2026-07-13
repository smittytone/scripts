#!/usr/bin/env python3

import json
from typing import Any
from fastkml import KML
from fastkml.utils import find, find_all
from fastkml import Placemark
from pathlib import Path

def output_geoson(data: str, ext: str):
    base_path: str = "/Users/smitty/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Mapping/Classical Anatolia." + ext
    file_path = Path(base_path)
    with open(file_path, "w", newline="") as f:
        f.write(json.dumps(data))

features = []

kml_data = KML.parse("/Users/smitty/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Mapping/Classical Anatolia.kml")
placemarks = list(find_all(kml_data, of_type=Placemark))
for placemark in placemarks:
    coords = placemark.geometry.coords[0]

    feature = {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [coords[1], coords[0], coords[2]]},
        "properties": {
            "name": placemark.name,
            "description": placemark.name
        },
    }

    features.append(feature)

# Save the GeoJson
geojson: dict[str, Any] = {"type": "FeatureCollection", "features": features}
output_geoson(geojson, "json")
output_geoson(geojson, "geojson")

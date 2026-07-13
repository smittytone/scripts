#!/usr/bin/env python3

import os
import sys
import json
import yaml

if __name__ == '__main__':
    if len(sys.argv) > 1:
        for index, item in enumerate(sys.argv):
            file_ext = os.path.splitext(item)[1]
            if file_ext == ".json":
                file_name = os.path.splitext(item)[0]
                with open(file_name + ".yaml", "w") as file:
                    file.write(yaml.dump(json.load(open(item))))

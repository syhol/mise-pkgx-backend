#!/bin/bash

set -e

source test/assert.sh

tool="$PLUGIN_NAME:gnu.org/tar"

mise install "$tool@1.35"

result=$(mise exec "$tool" -- tar --version)

assert_contain "$result" "tar (GNU tar) 1.35"


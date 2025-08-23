#!/bin/bash

set -e

source test/assert.sh

tool="$PLUGIN_NAME:gnu.org/tar"

mise install "$tool"

result=$(mise exec "$tool" -- tar --version)

assert_contain "$result" "tar (GNU tar) 1.35"


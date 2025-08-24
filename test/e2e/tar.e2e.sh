#!/bin/bash

set -e

source test/assert.sh

tool="$PLUGIN_NAME:gnu.org/tar"

assert_contain "$(mise ls-remote "$tool")" "1.35"

result=$(mise exec "$tool@1.35" -- tar --version)
assert_contain "$result" "tar (GNU tar) 1.35"

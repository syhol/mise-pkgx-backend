#!/bin/bash

set -e

source test/assert.sh

tool="$PLUGIN_NAME:git-scm.org"

assert_contain "$(mise ls-remote "$tool")" "2.51"

result=$(mise exec "$tool@2.51" -- git --version)
assert_contain "$result" "git version 2.51"

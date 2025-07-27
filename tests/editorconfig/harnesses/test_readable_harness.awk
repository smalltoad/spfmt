#!/usr/bin/awk -f

# File: test_readable_harness.bats
# Desc: Wrapper for editorconfig.awk function of test_readable to print results.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

BEGIN {
    result = test_readable()
    print result
}

#!/usr/bin/awk -f

# File: strip_leading_whitespace_harness.bats
# Desc: Wrapper for parse.awk function of strip_leading_whitespace to print results.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

{
    result = strip_leading_whitespace($0)
    print result
}

#!/usr/bin/awk -f

# File: call_strip_ltrailing_whitespace.bats
# Desc: Wrapper for parse.awk function of strip_trailing_whitespace to print results.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

{
    result = strip_trailing_whitespace($0)
    print result
}

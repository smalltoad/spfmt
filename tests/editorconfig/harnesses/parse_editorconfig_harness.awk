#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for editorconfig.awk function of parse_editorconfig to print results.
# File: parse_editorconfig_harness.bats
# License: GNU GPLv3

{
    # These must match what is in the _parse_editorconfig function to get set.
    indent_size
    indent_char

    result = _parse_editorconfig($0)
    print indent_size ":" indent_char
}

function strip_leading_whitespace(line) {
    return line
}

function strip_trailing_whitespace(line) {
    return line
}

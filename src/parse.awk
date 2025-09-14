#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: POSIX-compliant AWK script to provide common parsing functionality.
# File: parse.awk
# License: GNU GPLv3

function strip_leading_whitespace(line) {
    sub("^[ \t]+", "", line)
    return line
}

function strip_trailing_whitespace(line) {
    sub("[ \t]+$", "", line)
    return line
}

function strip_inline_comment(line) {
    sub("/#.*$/", "", line)
    return line
}

# TODO: Create tests for this function.
function trim_line(line) {
    line = strip_leading_whitespace(line)
    line = strip_trailing_whitespace(line)
}

# TODO: Find a better home for this function.
function is_a_number(line) {
    if (line ~ /^[0-9]+$/) {
        return 0
    }
    return 1
}

# TODO: Make this function resolve correctly.
function is_an_indent(line) {
    if (line ~ /^space+$/) {
        return " "
    } else if (line ~ /^tab+$/) {
        return "\t"
    }
    return 1

}

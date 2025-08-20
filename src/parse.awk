#!/usr/bin/awk -f

# File: parse.awk
# Description: POSIX-compliant AWK script to provide common pasing functionality.
# Author: Joseph Mowery <mowery.joseph@outlook.com>
# Usage: awk -f spfmt.awk -f parse.awk input_file.sh

BEGIN {
    leading_whitespace = "^[ \t]+"
    trailing_whitespace = "[ \t]+$"
    inline_comment = "/#.*$/"
}

function strip_leading_whitespace(line) {
    sub(leading_whitespace, "", line)
    return line
}

function strip_trailing_whitespace(line) {
    sub(trailing_whitespace, "", line)
    return line
}

function strip_inline_comment(line) {
    sub(inline_comment, "", line)
    return line
}

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

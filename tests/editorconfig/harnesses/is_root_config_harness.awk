#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for editorconfig.awk function of is_root_config to print results.
# File: is_root_config_harness.bats
# License: GNU GPLv3

{
    result = _is_root_config($0)
    print result
}

function strip_leading_whitespace(line) {
    return line
}

function strip_trailing_whitespace(line) {
    return line
}

function strip_inline_comment(line) {
    return line
}

#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of is_root_config to print results.
#
# [FILE] is_root_config_harness.bats
# [LICESNE] GNU GPLv3
# */

{
    result = _is_root_config($0)
    print result
}

# Mocks below all simply return the input.

function strip_leading_whitespace(line) {
    return line
}

function strip_trailing_whitespace(line) {
    return line
}

function strip_inline_comment(line) {
    return line
}

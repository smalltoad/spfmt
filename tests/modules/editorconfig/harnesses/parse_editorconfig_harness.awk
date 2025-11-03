#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of parse_editorconfig to print results.
#
# [FILE] parse_editorconfig_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    # These must match what is in the _parse_editorconfig function to get set.
    effective["indent_char"] = indent_char
    effective["indent_size"] = indent_size
    overrides["indent_char"] = indent_char_overriden
    overrides["indent_size"] = indent_size_overriden

    result = _parse_editorconfig($0)
    print effective["indent_size"] ":" effective["indent_char"]
}

# These stubs assume all lines are perfectly formatted.
function strip_leading_whitespace(line) {
    return line
}

function strip_trailing_whitespace(line) {
    return line
}

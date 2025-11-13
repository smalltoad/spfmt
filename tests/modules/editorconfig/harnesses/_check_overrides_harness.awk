#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of _check_overrides to print results.
#
# [FILE] _check_overrides_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    #/**
    # Can't pass associative arrays directly through the CLI.
    # Must set them within the harness instead!
    # */
    overrides["indent_char"] = indent_char_overriden
    overrides["indent_size"] = indent_size_overriden

    # _check_overrides is a bitwise operation on all configurable values.
    _check_overrides()

    # Print where _check_overrides stores the result.
    print defaults_overriden
}

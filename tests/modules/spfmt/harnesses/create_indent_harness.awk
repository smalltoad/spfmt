#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for spfmt.awk function of create_indent_harness to print results.
# File: create_indent_harness.bats
# License: GNU GPLv3

{
    # Initialize in scope.
    current_level
    effective["indent_size"]
    effective["indent_char"]

    # Repalce stubs above with a passed mock value for testing.
    if (ENVIRON["MOCK_LEVEL"] != "") {
        current_level = ENVIRON["MOCK_LEVEL"]
    }
    if (ENVIRON["MOCK_INDENT_SIZE"] != "") {
        effective["indent_size"] = ENVIRON["MOCK_INDENT_SIZE"]
    }
    if (ENVIRON["MOCK_INDENT_CHAR"] != "") {
        effective["indent_char"] = ENVIRON["MOCK_INDENT_CHAR"]
    }

    print create_indent()
}

#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for file_utils.awk function of test_readable to print results.
# File: test_readable_harness.bats
# License: GNU GPLv3

BEGIN {
    # Get command line arguments
    getline args < "/dev/stdin"

    argc = split(args, argv, ":")

    if (argc == 2) {
        target_path = argv[1]
        flag_value = argv[2]

        result = _test_with_flag(target_path, flag_value)

        print result
    } else {
        print "[ERROR] Expected 2 parameters separated by ':'"
        exit 1
    }
}

#/**
# * For testing purposes, this function can be mocked out to return exactly
# * what gets passed in. if we want to mock a success on this function, pass in
# * non-empty string. Otherwise pass in "".
# */
function _value_of_flag(arg) {
    # AWK Convention for a false value.
    if (arg == "" || arg == 0) {
        return ""
    }

    # Passed arg must be true. Return true.
    return "some_non-null_value"
}

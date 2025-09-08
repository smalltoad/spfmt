#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for spfmt.awk function of parse_arguments to print results.
# File: parse_arguments_harness.bats
# License: GNU GPLv3

{
    to_print = ""

    # Removes "-" argument used to stop reading input.
    delete ARGV[1]

    ret = parse_arguments()

    if (ret == 0) {
        if(ENVIRON["HELP_FLAG"] == "SHOW_HELP") {
            to_print += show_help
        }
        if (ENVIRON["DEBUG_FLAG"] == "DEBUG") {
            to_print += debug
        }
        if (ENVIRON["VERSION_FLAG"] == "SHOW_VERSION") {
            to_print += show_version
        }
        if (ENVIRON["SIZE_FLAG"] == "TRUE") {
            to_print = defaults_overriden ":" indent_size
        }
        if (ENVIRON["CHAR_FLAG"] == "TRUE") {
            to_print = defaults_overriden ":" indent_char
        }

        print to_print
    } else {
        # Exit with the same code returned to prevent continued parsing.
        exit ret
    }
}

function is_a_number(line) {
    # Mock control environment variable will store literal return result.
    if (ENVIRON["MOCK_IS_A_NUMBER_RESULT"] == "false") {
        return 1  # Return false (directory doesn't exist).
    } else if (ENVIRON["MOCK_IS_A_NUMBER_RESULT"] == "true") {
        return 0  # Return true (directory exists).
    } else {
        # Fallback to false if expected environ not found.
        return 1
    }
}

function is_an_indent(line) {
    # Mock control environment variable will store literal return result.
    if (ENVIRON["MOCK_IS_AN_INDENT_RESULT"] == "false") {
        return 1  # Return false (directory doesn't exist).
    } else if (ENVIRON["MOCK_IS_AN_INDENT_RESULT"] == "true") {
        return 0  # Return true (directory exists).
    } else {
        # Fallback to false if expected environ not found.
        return 1
    }
}

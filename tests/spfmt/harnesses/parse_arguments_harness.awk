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
    file_count = 0 # Needed for initalization in printing.
    # Removes stdin indicator "-" argument used to stop reading input.
    delete ARGV[1]

    ret = parse_arguments()

    if (ret == 0) {
        # Return code.
        printf("RETURN_CODE=%d\n", return_code)

        # Boolean flags.
        printf("SHOW_HELP=%d\n", show_help ? 1 : 0)
        printf("SHOW_VERSION=%d\n", show_version ? 1 : 0)
        printf("DEBUG=%d\n", debug ? 1 : 0)
        printf("IN_PLACE=%d\n", in_place ? 1 : 0)
        printf("DEFAULTS_OVERRIDDEN=%d\n", defaults_overriden ? 1 : 0)

        # Print configuration values.
        printf("INDENT_SIZE=%s\n", indent_size != "" ? indent_size : "UNSET")
        printf("INDENT_CHAR=%s\n", indent_char != "" ? indent_char : "UNSET")

        # Print file processing information.
        printf("FILE_COUNT=%d\n", file_count ? file_count : 0)

        # Print file list if any files were found.
        if (0 < file_count) {
            printf("FILES=")
            for (i = 0; i < file_count; i++) {
                if (i > 0) {
                    printf(",") # First run prints nothing
                }
                printf("%s", file_list[i])
            }
            printf("\n")
        } else {
            printf("FILES=NONE\n")
        }
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

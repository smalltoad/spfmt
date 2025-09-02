#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the parse_arguments function in the spfmt.awk module.
# File: test_parse_arguments.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function parse_arguments(i, arg) {
#     for (i = 1; i < ARGC; i++) {
#         arg = ARGV[i]
#
#         if (arg == "-h" || arg == "--help") {
#             show_help = 1
#             ARGV[i] = ""
#         }
#         else if (arg == "-v" || arg == "--version") {
#             show_version = 1
#             ARGV[i] = ""
#         }
#         else if (arg == "-d" || arg == "--debug") {
#             debug = 1
#             ARGV[i] = ""
#         }
#         else if (arg == "-i" || arg == "--in-place") {
#             in_place = 1
#             ARGV[i] = ""
#         }
#         else if (arg == "-s" || arg == "--indent-size") {
#             if (i + 1 < ARGC && ARGV[i + 1] ~ /^[0-9]+$/) {
#                 defaults_overriden = 1
#                 indent_size = ARGV[i + 1]
#                 ARGV[i] = ""
#                 ARGV[i + 1] = ""
#                 i++
#             }
#             else {
#                 print\
#                     "[ERROR] -s|--indent-size requires a positive integer"
#                 exit 2
#             }
#         }
#         else if (arg == "-c" || arg == "--indent-char") {
#             if (i + 1 < ARGC) {
#                 defaults_overriden = 1
#                 indent_char = ARGV[i + 1]
#                 ARGV[i] = ""
#                 ARGV[i + 1] = ""
#                 i++
#             }
#             else {
#                 print\
#                     "[ERROR] -c|--indent-char requires a character"
#                 exit 2
#             }
#         }
#         else if (arg ~ /^-/) {
#             printf("Error: Unknown option: %s\n", arg)
#             print "Use --help for usage information"
#             exit 2
#         }
#         else {
#             file_list[file_count] = arg
#             file_count++
#             ARGV[i] = ""
#         }
#     }
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="spfmt.awk"

# Harness to call specific FUT
harness="parse_arguments_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:BEGIN:REGEX:{}")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    #rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] generate mock!" {
    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "- -h" \
        -x "1"
}

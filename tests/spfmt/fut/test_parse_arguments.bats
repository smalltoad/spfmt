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
    mocked_script_path=$(mock_script "${script}:BEGIN:END:REGEX:{}")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    #rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] Show help flag correctly sets flag for help" {
    flag="- -h"
    env="HELP_FLAG=\"SHOW_HELP\""
    expected="RETURN_CODE=0
SHOW_HELP=1
SHOW_VERSION=0
DEBUG=0
IN_PLACE=0
DEFAULTS_OVERRIDDEN=0
INDENT_SIZE=UNSET
INDENT_CHAR=UNSET
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Debug flag correctly sets flag for debug mode" {
    flag="- -d"
    env="DEBUG_FLAG=\"DEBUG\""
    expected="RETURN_CODE=0
SHOW_HELP=0
SHOW_VERSION=0
DEBUG=1
IN_PLACE=0
DEFAULTS_OVERRIDDEN=0
INDENT_SIZE=UNSET
INDENT_CHAR=UNSET
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Help and debug flags get set correctly simultaneously" {
    flag="- -d -h"
    env="HELP_FLAG=\"SHOW_HELP\" DEBUG_FLAG=\"DEBUG\""
    expected="RETURN_CODE=0
SHOW_HELP=1
SHOW_VERSION=0
DEBUG=1
IN_PLACE=0
DEFAULTS_OVERRIDDEN=0
INDENT_SIZE=UNSET
INDENT_CHAR=UNSET
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Help, debug and version flags get set correctly simultaneously" {
    flag="- -d -h -v"
    env="HELP_FLAG=\"SHOW_HELP\" DEBUG_FLAG=\"DEBUG\" VERSION_FLAG=\"SHOW_VERSION\""
    expected="RETURN_CODE=0
SHOW_HELP=1
SHOW_VERSION=1
DEBUG=1
IN_PLACE=0
DEFAULTS_OVERRIDDEN=0
INDENT_SIZE=UNSET
INDENT_CHAR=UNSET
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Setting indent_char correctly sets override flag and gets the correct value for a real number" {
    flag="- -c space"
    env="CHAR_FLAG=\"TRUE\" MOCK_IS_AN_INDENT_RESULT=\"true\""
    expected="RETURN_CODE=0
SHOW_HELP=0
SHOW_VERSION=0
DEBUG=0
IN_PLACE=0
DEFAULTS_OVERRIDDEN=1
INDENT_SIZE=UNSET
INDENT_CHAR=space
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Setting indent_char correctly sets override flag and gets the correct value for a fake number" {
    flag="- -c space"
    env="CHAR_FLAG=\"TRUE\" MOCK_IS_AN_INDENT_RESULT=\"false\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -c "2" \
        -x "[ERROR] -c|--indent-char requires a character"
}

@test "[TEST] Setting indent_size correctly sets override defaults flag and gets the correct value for a real number" {
    flag="- -s 4"
    env="SIZE_FLAG=\"TRUE\" MOCK_IS_A_NUMBER_RESULT=\"true\""
    expected="RETURN_CODE=0
SHOW_HELP=0
SHOW_VERSION=0
DEBUG=0
IN_PLACE=0
DEFAULTS_OVERRIDDEN=1
INDENT_SIZE=4
INDENT_CHAR=UNSET
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Setting indent_size incorrectly does not override defaults flag and results in no value for a fake number" {
    flag="- -s notanumber"
    env="SIZE_FLAG=\"TRUE\" MOCK_IS_A_NUMBER_RESULT=\"false\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -c "2" \
        -x "[ERROR] -s|--indent-size requires a positive integer"
}

@test "[TEST] Unsupported flag will no added option will cause early exit" {
    flag="- -p"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -c "2" \
        -x "[ERROR] Unknown option: -p
[ERROR] Use --help for usage information"
}

@test "[TEST] Unsupported flag with option will cause early exit" {
    flag="- -p breakitdown"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -c "2" \
        -x "[ERROR] Unknown option: -p
[ERROR] Use --help for usage information"
}

@test "[TEST] Unsupported flag with option when preceeding a valid option will cause early exit" {
    flag="- -s 2 -p breakitdown"
    env="SIZE_FLAG=\"TRUE\" MOCK_IS_A_NUMBER_RESULT=\"true\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -c "2" \
        -x "[ERROR] Unknown option: -p
[ERROR] Use --help for usage information"
}

@test "[TEST] Can correctly set indent size and char at the same time" {
    flag="- -s 4 -c space"
    env="SIZE_FLAG=\"TRUE\" MOCK_IS_A_NUMBER_RESULT=\"true\" CHAR_FLAG=\"TRUE\" MOCK_IS_AN_INDENT_RESULT=\"true\""
    expected="RETURN_CODE=0
SHOW_HELP=0
SHOW_VERSION=0
DEBUG=0
IN_PLACE=0
DEFAULTS_OVERRIDDEN=1
INDENT_SIZE=4
INDENT_CHAR=space
FILE_COUNT=0
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] Files read in get correctly added to file list" {
    flag="- -f file1.txt -f file2.awk"
    expected="RETURN_CODE=0
SHOW_HELP=0
SHOW_VERSION=0
DEBUG=0
IN_PLACE=0
DEFAULTS_OVERRIDDEN=0
INDENT_SIZE=UNSET
INDENT_CHAR=UNSET
FILE_COUNT=2
FILES=NONE"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -s "${flag}" \
        -x "${expected}"
}

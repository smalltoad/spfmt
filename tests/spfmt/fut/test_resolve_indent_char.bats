#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the resolve_indent_char function in the spfmt.awk module.
# File: test_resolve_indent_char.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function resolve_indent_char() {
#     if (indent_char == "space") {
#         indent_char = " "
#     } else if (indent_char == "tab") {
#         indent_char = "\t"
#     } else {
#         return 1
#     }
#
#     return 0
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="spfmt.awk"

# Harness to call specific FUT
harness="resolve_indent_char_harness.awk"

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

@test "resolve_indent_char correctly resolves space" {
    vars="indent_char=space"
    expected=" "

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the create_indent function in the spfmt.awk module.
# File: test_create_indent.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# AWK script containing FUT
script="spfmt.awk"

# Harness to call specific FUT
harness="create_indent_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:BEGIN:END:REGEX:{}")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "create_indent prints the correct indent for starting level" {
    env="MOCK_LEVEL=\"0\" MOCK_INDENT_SIZE=\"2\" MOCK_INDENT_CHAR=\" \""
    expected=""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "create_indent prints the correct indent for 1 level deep" {
    env="MOCK_LEVEL=\"1\" MOCK_INDENT_SIZE=\"2\" MOCK_INDENT_CHAR=\" \""
    expected="  "

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "create_indent prints the correct indent for 2 levels deep" {
    env="MOCK_LEVEL=\"2\" MOCK_INDENT_SIZE=\"2\" MOCK_INDENT_CHAR=\" \""
    expected="    "

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "create_indent prints the correct indent for many levels deep" {
    env="MOCK_LEVEL=\"50\" MOCK_INDENT_SIZE=\"2\" MOCK_INDENT_CHAR=\" \""
    expected=$(printf '%100s' '')

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

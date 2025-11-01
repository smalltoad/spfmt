#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the ensure_indent_size function in the spfmt.awk module.
# File: test_ensure_indent_size.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# AWK script containing FUT
script="spfmt.awk"

# Harness to call specific FUT
harness="ensure_indent_size_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "$(realpath "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash")"

setup_file() {
    log_test_start

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:BEGIN:END:REGEX:{}")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    log_test_end
}

@test "[TEST] ensure_indent_size returns true for the lower boundry" {
    vars="indent_size=0"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns true for single diget" {
    vars="indent_size=9"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns true for greatly above the lower boundry" {
    vars="indent_size=5000"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns false for non integer value of decimal" {
    vars="indent_size=1.6"
    remove='\[ERROR\].*$'
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -r "${remove}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns false for non integer value of word" {
    vars="indent_size=notanumber!"
    remove='\[ERROR\].*$'
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -r "${remove}" \
        -x "${expected}"
}

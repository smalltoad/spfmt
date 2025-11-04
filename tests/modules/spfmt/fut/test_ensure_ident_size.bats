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

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="spfmt.awk"
harness="ensure_indent_size_harness.awk"

setup_file() {
    log_test_start

    mock=$(mock_script "${script}" "BEGIN:END:REGEX:{}")
    export mock
}

teardown_file() {
    clean_mock "${mock}"

    log_test_end
}

@test "[TEST] ensure_indent_size returns true for the lower boundry" {
    vars="indent_size=0"
    expected="0"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns true for single diget" {
    vars="indent_size=9"
    expected="0"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns true for greatly above the lower boundry" {
    vars="indent_size=5000"
    expected="0"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] ensure_indent_size returns false for non integer value of decimal" {
    vars="indent_size=1.6"
    remove='\[ERROR\].*$'
    expected="1"

    assert_builder \
        -m "${mock}" \
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
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -r "${remove}" \
        -x "${expected}"
}

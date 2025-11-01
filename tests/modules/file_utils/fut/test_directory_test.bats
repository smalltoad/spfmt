#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the test_directory function in the editorconfig.awk module.
# File: test_directory_test.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "$(realpath "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash")"

setup_file() {
    log_test_start
}

# Runs for each @test case
setup() {
    # AWK script containing FUT
    script="file_utils.awk"

    # Harness to call specific FUT
    harness="test_directory_harness.awk"
}

teardown_file() {
    log_test_end
}

#============#
# TEST CASES #
#============#

@test "[TEST] test_directory returns false when empty string is passed" {
    input="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] test_directory returns true when root directory is passed" {
    input="/"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] test_directory returns true when valid directory is passed" {
    input=$(mktemp -d)
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

    rmdir "${input}"
}

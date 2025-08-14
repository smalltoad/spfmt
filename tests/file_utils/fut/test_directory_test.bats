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

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# NOTE: This function is a wrapper around _test_with_flag, for implementation
# details refer to test_with_flag_test.bats

# function test_directory(target, flag) {
#     return _test_with_flag(target, "d")
# }

#========#
# SET UP #
#========#

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3
}

# Runs for each @test case
setup() {
    # AWK script containing FUT
    script="file_utils.awk"

    # Harness to call specific FUT
    harness="test_directory_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

teardown_file() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
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

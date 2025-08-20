#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the get_parent_directory function in the editorconfig.awk module.
# File: get_parent_directory.bats
# License: GNU GPLv3
#
# Comandline execution examples:
#     $ bats get_parent_directory.bats
#     $ ./tests/editorconfig/fut/get_parent_directory.bats
# With INFO turned on:
#     $ INFO=1 ./tests/editorconfig/fut/get_parent_directory.bats
# With TAP compliant output:
#     $ bats get_parent_directory.bats --tap

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function get_parent_directory(path,    cmd, _result) {
#     cmd = "dirname \"" path "\""
#
#     cmd | getline _result
#     close(cmd)
#
#     return _result
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="editorconfig.awk"

# Harness to call specific FUT
harness="get_parent_directory_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3
}

teardown_file() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] get_parent_directory returns root for root directory" {
    input="/"
    expected="/"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns root for boot directory" {
    input="/boot"
    expected="/"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns true for single nested directory" {
    input="/shrimp/are"
    expected="/shrimp"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns true for double nested directory" {
    input="/shrimp/are/bugs"
    expected="/shrimp/are"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns true for directory with a space" {
    input="/shrimp/are /bugs"
    expected="/shrimp/are "

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns true for directory with a hyphen" {
    input="/shrimp/are-/bugs"
    expected="/shrimp/are-"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns true for directory with only numbers" {
    input="/shrimp/1337/bugs"
    expected="/shrimp/1337"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

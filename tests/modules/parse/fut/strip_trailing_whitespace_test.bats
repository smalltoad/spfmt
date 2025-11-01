#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the strip_leading_whitespace function in the parse.awk module.
# File: strip_leading_whitespace_test.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "$(realpath "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash")"

setup_file() {
    log_test_start
}

# Runs for each @test case
setup() {
    # AWK script containing FUT
    script="parse.awk"

    # Harness to call specific FUT
    harness="strip_trailing_whitespace_harness.awk"
}

teardown_file() {
    log_test_end
}

#============#
# TEST CASES #
#============#

@test "[TEST] strip_trailing_whitespace removes whitespace from stdin at beginning of line" {
    # Test case input with leading spaces
    input="hello world       "
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace removes tabs from stdin at beginning of line" {
    # Test case input with leading tab
    input=$(printf "hello world\t")
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace edge case of empty string" {
    # Test case input with no characters or whitespace.
    input=""
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace edge case of whitespace only string" {
    # Test case input with no characters or whitespace.
    input="   "
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace handles nulls" {
    # Test case input with null bytes.
    input=$(printf 'hello world\x00\x00\x00')
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace preserves windows line ending CR + LF" {
    # Test case input with windows style carriage return ending.
    input=$(printf 'hello world\r\n')
    expected=$(printf 'hello world\r\n')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace preserves linux style newlines" {
    # Test case input with linux line feed line ending.
    input=$(printf 'hello world\n')
    expected=$(printf 'hello world\n')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace preserves carriage returns" {
    # Test case input with windows style line ending.
    input=$(printf 'hello world\r')
    expected=$(printf 'hello world\r')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_trailing_whitespace removes spaces and tabs from file at beginning of lines" {
    # Input data file
    input="trailing_whitespace_lines.txt"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -o "${input}"
}

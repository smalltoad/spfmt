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
#
# Comandline execution examples:
#     $ bats strip_trailing_whitespace_test.bats
#     $ ./tests/parse/fut/strip_trailing_whitespace_test.bats
# With INFO turned on:
#     $ INFO=1 ./tests/parse/fut/strip_trailing_whitespace_test.bats
# With TAP compliant output:
#     $ bats strip_trailing_whitespace_test.bats --tap

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function strip_leading_whitespace(line) {
#    sub(/^[ \t]+/, "", line)
#    return line
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
    script="parse.awk"

    # Harness to call specific FUT
    harness="strip_trailing_whitespace_harness.awk"

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

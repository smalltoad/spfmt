#!/usr/bin/env bats

# File: strip_leading_whitespace_test.bats
# Desc: BATS tests for the strip_leading_whitespace function in the parse.awk module.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function strip_leading_whitespace(line) {
#     sub(/^[ \t]+/, "", line)
#     return line
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
    harness="strip_leading_whitespace_harness.awk"

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

@test "[TEST] strip_leading_whitespace removes whitespace from stdin at beginning of line" {
    input="               hello world"
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] strip_leading_whitespace removes tabs from stdin at beginning of line" {
    input=$(printf "\thello world")
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace edge case of empty string" {
    input=""
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace edge case of only whitespace string" {
    input="   "
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace handles nulls" {
    # Test case input with null bytes.
    input=$(printf '\x00\x00\x00hello world')
    expected="hello world"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace preserves windows line endings CR + LF" {
    # Test case input with windows style carriage return ending.
    input=$(printf '\r\nhello world')
    expected=$(printf '\r\nhello world')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace preserves linux style newlines" {
    # Test case input with linux line feed line ending.
    input=$(printf '\nhello world')
    expected=$(printf '\nhello world')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace preserves carriage returns" {
    # Test case input with windows style line ending.
    input=$(printf '\rhello world')
    expected=$(printf '\rhello world')

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"

}

@test "[TEST] strip_leading_whitespace removes spaces and tabs from file at beginning of lines" {
    input="leading_whitespace_lines.txt"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -o "${input}"
}

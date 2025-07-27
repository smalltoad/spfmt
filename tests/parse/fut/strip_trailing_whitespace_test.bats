#!/usr/bin/env bats

# File: strip_leading_whitespace_test.bats
# Desc: BATS tests for the strip_leading_whitespace function in the parse.awk module.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function strip_leading_whitespace(line) {
#    sub(/^[ \t]+/, "", line)
#    return line
# }

#=========#
# GLOBALS #
#=========#

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

#============#
# BATS HOOKS #
#============#

# Runs for each @test case
setup() {
    # Environment file for BATS
    #bats_env="${BATS_TEST_DIRNAME}/../../../bats_env"
    #. "${bats_env}"

    # AWK script containing FUT
    parse_awk_script="parse.awk"

    # Harness to call specific FUT
    parse_awk_harness="strip_trailing_whitespace_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

#============#
# TEST CASES #
#============#

@test "${MAGENTA}[TEST] strip_trailing_whitespace removes whitespace from stdin at beginning of line${RESET}" {
    # Test case input with leading spaces
    test_input="hello world       "
    expected_result="hello world"

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace removes tabs from stdin at beginning of line${RESET}" {
    # Test case input with leading tab
    test_input=$(printf "hello world\t")
    expected_result="hello world"

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace edge case of empty string${RESET}" {
    # Test case input with no characters or whitespace.
    test_input=""
    expected_result=""

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace edge case of whitespace only string${RESET}" {
    # Test case input with no characters or whitespace.
    test_input="   "
    expected_result=""

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace handles nulls${RESET}" {
    # Test case input with null bytes.
    test_input=$(printf 'hello world\x00\x00\x00')
    expected_result="hello world"

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace preserves windows line ending CR + LF${RESET}" {
    # Test case input with windows style carriage return ending.
    test_input=$(printf 'hello world\r\n')
    expected_result=$(printf 'hello world\r\n')

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace preserves linux style newlines${RESET}" {
    # Test case input with linux line feed line ending.
    test_input=$(printf 'hello world\n')
    expected_result=$(printf 'hello world\n')

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace preserves carriage returns${RESET}" {
    # Test case input with windows style line ending.
    test_input=$(printf 'hello world\r')
    expected_result=$(printf 'hello world\r')

    assert_awk_stdin "${parse_awk_script}" "${parse_awk_harness}" "${test_input}" "${expected_result}"
}

@test "${MAGENTA}[TEST] strip_trailing_whitespace removes spaces and tabs from file at beginning of lines${RESET}" {
    # Input data file
    input_test_file="trailing_whitespace_lines.txt"

    asset_awk_file "${parse_awk_script}" "${parse_awk_harness}" "${input_test_file}"
}

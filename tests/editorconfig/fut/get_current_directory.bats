#!/usr/bin/env bats

# File: get_current_directory.bats
# Desc: BATS tests for the get_current_directory function in the editorconfig.awk module.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function get_current_dir() {
#     current_dir = ENVIRON["PWD"]
#
#     if (!current_dir || !test_directory(current_dir)) { current_dir = "." }
#
#     return current_dir
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
    # AWK script containing FUT.
    script="editorconfig.awk"

    # Harness to call specific FUT.
    harness="get_current_directory_harness.awk"

    # BATS helpers.
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

teardown_file() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

#================#
# MC/DC COVERAGE #
#================#

# **/
# * Boolean expression under test: if (!current_dir || !test_directory(current_dir))
# *
# * Conditions:
# *     A = !current_dir                  (true current directory is not set or is 0)
# *     B = !test_directory(current_dir)  (true when current current directory is not real)
# *
# * Simplified decision is now: ( A || B )
# *
# * MC/DC Test Case Matrix:
# * +------+---+---+-------+-------------------+
# * | Case | A | B | A||B  | MC/DC Pairs       |
# * +------+---+---+-------+-------------------+
# * |  1   | T | T |   T   |                   |
# * |  2   | T | F |   T   | A (4,2)           |
# * |  3   | F | T |   T   | B (4,3)           |
# * |  4   | F | F |   F   | A (2,4) / B (3,4) |
# * +------+---+---+-------+-------------------+
# *
# * Condition A Independence Evident Through: Cases 2 & 4
# * Test cases are...
# *        A || B
# *     2: T || F = T
# *     4: F || F = F
# * While B remains constant, A changing independantly changes the outcome.
# *
# * Condition B Independence Evident Through: Cases 3 & 4
# * Test cases are...
# *        A || B
# *     3: F || T = T
# *     4: F || F = F
# * While A remains constant, B changing independantly changes the outcome.
# *
# * Minimum Test Cases Required = 2 + 1 = 3
# * Chosen Test Points Are (2,3,4)
# *
# * Translation to Actual Values:
# * +------+---------------------+------------------------------------+-------------+---------------------+
# * | Case | (A = !current_dir)  | (B = !test_directory(current_dir)) | Result      | Expected            |
# * +------+---------------------+------------------------------------+-------------+---------------------+
# * |  2   | "" (empty)          | ENVIRON["MOCK_RESULT"] = true      | T || F = T  | "."                 |
# * |  3   | "\boot"             | ENVIRON["MOCK_RESULT"] = false     | F || T = T  | "."                 |
# * |  4   | "\shrimps\are\bugs" | ENVIRON["MOCK_RESULT"] = true      | F || F = F  | "\shrimps\are\bugs" |
# * +------+---------------------+------------------------------------+-------------+---------------------+
# */

@test "[TEST] get_current_directory MC/DC test case for T||F should return T" {
    expected="."
    env="-u PWD MOCK_TEST_DIRECTORY_RESULT=\"true\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory MC/DC test case for F||T should return T" {
    expected="."
    env="PWD=\"\boot\" MOCK_TEST_DIRECTORY_RESULT=\"false\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory MC/DC test case for F||F should return F" {
    expected="\shrimps\are\bugs"
    env="PWD=\"\shrimps\are\bugs\" MOCK_TEST_DIRECTORY_RESULT=\"true\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] get_current_directory returns the correct absolute path" {
    # Nominal test case with normal pwd process environment variable.
    expected=$(pwd)

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}"
}

@test "[TEST] get_current_directory returns the "." when pwd is unset" {
    # Test case for PWD not set, should return default.
    expected="."
    env="-u PWD"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory handles PWD with only whitespace" {
    # Whitespace edge case, should still get caught by !current_dir.
    expected="."
    env="PWD=   "

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory handles PWD with non-real directory path" {
    # Should return "." if CWD is not real.
    expected="."
    env="MOCK_TEST_DIRECTORY_RESULT=\"false\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory handles PWD as root directory" {
    # The root directory edge/special case.
    expected="/"
    env="PWD=/"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"
}

@test "[TEST] get_current_directory handles PWD path ending with slash" {
    # Create tmp dir to test is paths with leading slash work.
    tmp_dir=$(mktemp -d)
    expected="${tmp_dir}/"
    env="PWD=${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -x "${expected}" \
        -e "${env}"

    rmdir "${tmp_dir}"
}

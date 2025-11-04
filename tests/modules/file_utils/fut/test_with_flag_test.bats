#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the test_with_flag function in the file_utils.awk module.
#
# [FILE] test_with_flag_test.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/tmp_folder_helper.bash"

script="file_utils.awk"
harness="test_with_flag_harness.awk"

setup_file() {
    log_test_start

    mock=$(mock_script "${script}" "_value_of_flag")
    export mock

    tmp_dir="$(get_temp_working_dir)"
    export tmp_dir
}

setup() {
    tmp_file="${tmp_dir}"/tmp_file.$$
    touch "${tmp_dir}"/tmp_file.$$ || false
}

teardown_file() {
    clean_mock "${mock}"
    rm -rf "${tmp_dir}"

    log_test_end
}

#================#
# MC/DC COVERAGE #
#================#

# **/
# * Boolean expression under test: if (!target || !_resolved_flag)
# *
# * Conditions:
# *     A = !target          (true when target is empty/null/false)
# *     B = !_resolved_flag  (true when _resolved_flag is empty/null/false)
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
# * +------+---------------+------------------+-------------+----------------+
# * | Case | (A = !target) | (B = !_res_flag) | Result      | Expected       |
# * +------+---------------+------------------+-------------+----------------+
# * |  2   | "" (empty)    | "f" (valid)      | T || F = T  | 1 (early ret)  |
# * |  3   | "/file.txt"   | ""  (empty)      | F || T = T  | 1 (early ret)  |
# * |  4   | "/file.txt"   | "f" (valid)      | F || F = F  | system() result|
# * +------+---------------+------------------+-------------+----------------+
# */

@test "[TEST] _test_with_flag early exit MC/DC test case for T||F should return T" {
    # shellcheck disable=SC2030 # Intentionally segmented in BATs subshell.
    tmp_file=""
    flag="f"
    expected="1"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"
}

@test "[TEST] _test_with_flag early exit MC/DC test case for F||T should return T" {
    flag=""
    expected="1"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_file}:${flag}" \
            -x "${expected}"
    }
}

#/**
# [NOTE]
# The F||F test case for MC/DC is carried out later as it moves past the actual
# conditional being tested and has more handling involved.
# */
#@test "[TEST] _test_with_flag early exit MC/DC test case for F||F should return F" {
#    flag="f"
#    expected="0"
#
#    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
#    {
#        assert_builder \
#            -m "${mock}" \
#            -h "${harness}" \
#            -i "${tmp_file}:${flag}" \
#            -x "${expected}"
#    }
#}

#======================#
# FILE FLAG TEST CASES #
#======================#

@test "[TEST] _test_with_flag returns true for supported flag -f and regular file" {
    flag="f"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_file}:${flag}" \
            -x "${expected}"
    }
}

@test "[TEST] _test_with_flag returns false for supported flag -f and directory file" {
    flag="f"
    expected="1"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"
}

@test "[TEST] _test_with_flag returns false for supported flag -f and non-existant file" {
    non_existent_file="/tmp/definitely/does/not/exist/_"$$
    flag="f"
    expected="1"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -i "${non_existent_file}:${flag}" \
        -x "${expected}"
}

#===========================#
# DIRECTORY FLAG TEST CASES #
#===========================#

@test "[TEST] _test_with_flag returns true for supported flag -d and directory" {
    flag="d"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_dir}:${flag}" \
            -x "${expected}"
    }
}

@test "[TEST] _test_with_flag returns false for supported flag -d and regular file" {
    flag="d"
    expected="1"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_file}:${flag}" \
            -x "${expected}"
    }
}

#==========================#
# READABLE FLAG TEST CASES #
#==========================#

@test "[TEST] _test_with_flag returns true for supported flag -r and regular file" {
    flag="r"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_file}:${flag}" \
            -x "${expected}"
    }
}

@test "[TEST] _test_with_flag returns true for supported flag -r and directory" {
    flag="r"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented in BATs subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${tmp_dir}:${flag}" \
            -x "${expected}"
    }
}

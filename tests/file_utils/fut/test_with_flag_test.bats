#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description:  BATS tests for the test_with_flag function in the file_utils.awk module.
# File: test_with_flag_test.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function _test_with_flag(target, flag,    _resolved_flag, _cmd, _result) {
#     _resolved_flag = _value_of_flag(flag)
#     _result = 1
#
#     if (!target || !_resolved_flag) {
#         return _result
#     }
#
#     _cmd = "test -"flag"  \"" target "\""
#     _result = system(_cmd)
#
#     return (_result)
# }

#========#
# SET UP #
#========#

# AWK script containing FUT.
script="file_utils.awk"

# Harness to call specific FUT.
harness="test_with_flag_harness.awk"

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:_value_of_flag")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3

    #rm -rf "${script}"
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

@test "[TEST] test_with_flag MC/DC test case for T||F should return T" {
    tmp_file=""
    flag="f"
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"
}

@test "[TEST] test_with_flag MC/DC test case for F||T should return T" {
    tmp_file="${BATS_TEST_TMPDIR}/test_file_"$$
    touch "${tmp_file}"
    flag=""
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_with_flag MC/DC test case for F||F should return F" {
    tmp_file="${BATS_TEST_TMPDIR}/test_file_"$$
    touch "${tmp_file}"
    flag="f"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

#=================#
# FILE TEST CASES #
#=================#

@test "[TEST] test_with_flag returns true for supported flag -f and regular file" {
    tmp_file="${BATS_TEST_TMPDIR}/test_file_"$$
    touch "${tmp_file}"
    flag="f"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_with_flag returns false for supported flag -f and directory file" {
    prefix="test_flag_${BATS_TEST_NUMBER}_${BASHPID}"
    tmp_dir=$(mktemp -d "${BATS_TEST_TMPDIR}/${prefix}.XXXXXX")
    flag="f"
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

@test "[TEST] test_with_flag returns false for supported flag -f and non-existant file" {
    non_existent_file="/tmp/definitely/does/not/exist/_"$$
    flag="f"
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${non_existent_file}:${flag}" \
        -x "${expected}"
}

#======================#
# DIRECTORY TEST CASES #
#======================#

@test "[TEST] test_with_flag returns true for supported flag -d and directory" {
    prefix="test_flag_d_dir_${BATS_TEST_NUMBER}_${BASHPID}"
    tmp_dir=$(mktemp -d "${BATS_TEST_TMPDIR}/${prefix}.XXXXXX")
    flag="d"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

@test "[TEST] test_with_flag returns false for supported flag -d and regular file" {
    prefix="test_flag_d_file_${BATS_TEST_NUMBER}_${BASHPID}"
    tmp_file=$(mktemp "${BATS_TEST_TMPDIR}/${prefix}.XXXXXX")

    if [[ ! -f "${tmp_file}" ]]; then
        fail "Failed to create test file: ${tmp_file}"
    fi

    flag="d"
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

#=====================#
# READABLE TEST CASES #
#=====================#

@test "[TEST] test_with_flag returns true for supported flag -r and regular file" {
    prefix="test_flag_r_file_${BATS_TEST_NUMBER}_${BASHPID}"
    tmp_file=$(mktemp "${BATS_TEST_TMPDIR}/${prefix}.XXXXXX")
    flag="r"
    expected="0"

    if [[ ! -f "${tmp_file}" ]]; then
        fail "Failed to create test file: ${tmp_file}"
    fi

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_with_flag returns true for supported flag -r and directory" {
    prefix="test_flag_r_directory_${BATS_TEST_NUMBER}_${BASHPID}"
    tmp_dir=$(mktemp -d "${BATS_TEST_TMPDIR}/${prefix}.XXXXXX")

    if [[ ! -d "${tmp_dir}" ]]; then
        fail "Failed to create test directory: ${tmp_dir}"
    fi

    flag="r"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

#=====================#
# BAD FLAG TEST CASES #
#=====================#

@test "[TEST] test_with_flag returns false for unsupported flag" {
    tmp_file="${BATS_TEST_TMPDIR}/test_file_"$$
    touch "${tmp_file}"
    flag=""
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

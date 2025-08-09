#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description:  BATS tests for the test_with_flag function in the editorconfig.awk module.
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

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

# Runs for each @test case.
setup() {
    # AWK script containing FUT.
    script="file_utils.awk"

    # Harness to call specific FUT.
    harness="test_with_flag_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

#=================#
# FILE TEST CASES #
#=================#

@test "${MAGENTA}[TEST] test_with_flag returns true for supported flag -f and regular file${RESET}" {
    tmp_file=$(mktemp)
    flag="f"
    expected="0"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "${MAGENTA}[TEST] test_with_flag returns false for supported flag -f and directory file${RESET}" {
    tmp_dir=$(mktemp -d)
    flag="f"
    expected="1"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

@test "${MAGENTA}[TEST] test_with_flag returns false for supported flag -f and non-existant file${RESET}" {
    non_existent_file="/tmp/definitely/does/not/exist/$(date +%s%N)"
    flag="f"
    expected="1"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${non_existent_file}:${flag}" \
        -x "${expected}"
}

#======================#
# DIRECTORY TEST CASES #
#======================#

@test "${MAGENTA}[TEST] test_with_flag returns true for supported flag -d and directory${RESET}" {
    tmp_dir=$(mktemp -d)
    flag="d"
    expected="0"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_dir}:${flag}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

@test "${MAGENTA}[TEST] test_with_flag returns false for supported flag -d and regular file${RESET}" {
    tmp_file=$(mktemp)
    flag="d"
    expected="1"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

#=====================#
# READABLE TEST CASES #
#=====================#

@test "${MAGENTA}[TEST] test_with_flag returns true for supported flag -r and regular file${RESET}" {
    tmp_file=$(mktemp)
    flag="r"
    expected="0"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "${MAGENTA}[TEST] test_with_flag returns true for supported flag -r and directory${RESET}" {
    tmp_file=$(mktemp)
    flag="r"
    expected="0"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

    rm "${tmp_file}"
}

#=====================#
# BAD FLAG TEST CASES #
#=====================#

@test "${MAGENTA}[TEST] test_with_flag returns false for unsupported flag${RESET}" {
    flag=""
    expected="1"

    assert_builder \
        -m "${script}:_value_of_flag" \
        -h "${harness}" \
        -i "${tmp_file}:${flag}" \
        -x "${expected}"

}

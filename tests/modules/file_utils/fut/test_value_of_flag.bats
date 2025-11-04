#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the _value_of_flag function in the file_utils.awk module.
#
# [FILE] test_value_of_flag.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="file_utils.awk"
harness="_value_of_flag_harness.awk"

setup_file() {
    log_test_start
}

teardown_file() {
    log_test_end
}

@test "[TEST] _value_of_flag recognizes readable (-r) flag" {
    flag="r"
    expected="readable"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${flag}" \
        -x "${expected}"
}

@test "[TEST] _value_of_flag recognizes file (-f) flag" {
    flag="f"
    expected="file"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${flag}" \
        -x "${expected}"
}

@test "[TEST] _value_of_flag recognizes directory (-d) flag" {
    flag="d"
    expected="directory"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${flag}" \
        -x "${expected}"
}

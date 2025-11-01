#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the get_parent_directory function in the editorconfig.awk module.
#
# [FILE] get_parent_directory.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

script="editorconfig.awk"
harness="get_parent_directory_harness.awk"

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

setup_file() {
    log_test_start
}

teardown_file() {
    log_test_end
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

@test "[TEST] get_parent_directory returns correct parent for single nested directory" {
    input="/shrimp/are"
    expected="/shrimp"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns correct parent for double nested directory" {
    input="/shrimp/are/bugs"
    expected="/shrimp/are"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns correct parent for directory with a space" {
    input="/shrimp/are /bugs"
    expected="/shrimp/are "

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns correct parent for directory with a hyphen" {
    input="/shrimp/are-/bugs"
    expected="/shrimp/are-"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] get_parent_directory returns correct parent for directory with only numbers" {
    input="/shrimp/1337/bugs"
    expected="/shrimp/1337"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

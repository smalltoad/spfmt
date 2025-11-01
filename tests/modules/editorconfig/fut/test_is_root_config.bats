#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the is_root_config function in the editorconfig.awk module.
# File: test_is_root_config.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

script="editorconfig.awk"
harness="is_root_config_harness.awk"

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

setup_file() {
    log_test_start
}

setup() {
    base="$(mktemp -d "/tmp/is_root_config_test.XXXXXX")"
    input="${base}"
}

teardown_file() {
    clean_mock "${mock}"
    log_test_end
}

teardown() {
    rm -rf "${base}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _is_root_config returns 1 for empty/null path" {
    # Test case that proves robustness, guarding against empty/null input.
    input=" "
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for newline path" {
    # Test case that proves robustness, guarding against empty/null input.
    input="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for empty editorconfig" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 for editorconfig path with only root = 1" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    echo "root = true" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 and loops correctly for editorconfig path with some data and root = 1" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "GARBAGE DATA\nroot = true\n" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 and early exits for editorconfig path with root = 1 and some data" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "root = true\nGARBAGE DATA\n" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

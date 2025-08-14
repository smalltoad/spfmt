#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description:  BATS tests for the test_readable function in the editorconfig.awk module.
# File: test_readable_test.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# NOTE: This function is a wrapper around _test_with_flag, for implementation
# details refer to either file_utils._test_with_flag or test_with_flag_test.bats

# function test_readable(target, flag) {
#     return _test_with_flag(target, "r")
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
    script="file_utils.awk"

    # Harness to call specific FUT
    harness="test_readable_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

teardown_file() {
    echo "#=== [END] ${BATS_TEST_FILENAME##*/} [END] ===#" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] test_readable returns true when everyone has full permissions (chmod 777)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has readable permissions everyone.
    # *      Owner (7): rwx
    # *                 111
    # *      Group (7): rwx
    # *                 111
    # *     Others (7): rwx
    # *                 111
    # */
    chmod 777 "${tmp_file}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_readable returns true when only owner has read permissions (chmod 644)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has readable permissions for owner only.
    # *      Owner (6): rwx
    # *                 110
    # *      Group (4): rwx
    # *                 010
    # *     Others (4): rwx
    # *                 010
    # */
    chmod 644 "${tmp_file}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_readable returns false when only no one has read permissions (chmod 333)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has readable permissions for no one.
    # *      Owner (3): rwx
    # *                 011
    # *      Group (3): rwx
    # *                 011
    # *     Others (3): rwx
    # *                 011
    # */
    chmod 333 "${tmp_file}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "[TEST] test_readable returns false for no permissions (chmod 000)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has zero permissions for everyone.
    # *      Owner (0): rwx
    # *                 000
    # *      Group (0): rwx
    # *                 000
    # *     Others (0): rwx
    # *                 000
    # */
    chmod 000 "${tmp_file}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
    rm "${tmp_file}"
}

@test "[TEST] test_readable returns false when only group has read (chmod 040)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has readable permissions group only.
    # *      Owner (0): rwx
    # *                 000
    # *      Group (4): rwx
    # *                 100
    # *     Others (0): rwx
    # *                 000
    # */
    chmod 040 "${tmp_file}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
    rm "${tmp_file}"
}

@test "[TEST] test_readable returns false when only others have read (chmod 004)" {
    tmp_file=$(mktemp)

    #/**
    # * Ensure the file has readable permissions for others only.
    # *      Owner (0): rwx
    # *                 000
    # *      Group (0): rwx
    # *                 000
    # *     Others (4): rwx
    # *                 010
    # */
    chmod 004 "${tmp_file}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
    rm "${tmp_file}"
}

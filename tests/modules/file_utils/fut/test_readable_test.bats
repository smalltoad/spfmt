#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the test_readable function in the editorconfig.awk module.
#
# [FILE] test_readable_test.bats
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
harness="test_readable_harness.awk"

setup_file() {
    log_test_start

    tmp_dir="$(get_temp_working_dir)"
    export tmp_dir
}

setup() {
    tmp_file="${tmp_dir}"/tmp_file.$$
    mkdir -p "${tmp_dir}"/tmp_file.$$ || false
}

teardown_file() {
    chmod +644 "${tmp_dir}"
    rm -rf "${tmp_dir}"

    log_test_end
}

#============#
# TEST CASES #
#============#

@test "[TEST] test_readable returns true when everyone has full permissions (chmod 777)" {
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
}

@test "[TEST] test_readable returns true when only owner has read permissions (chmod 644)" {
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
}

@test "[TEST] test_readable returns false when only no one has read permissions (chmod 333)" {
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
}

@test "[TEST] test_readable returns false for no permissions (chmod 000)" {
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
}

@test "[TEST] test_readable returns false when only group has read (chmod 040)" {
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
}

@test "[TEST] test_readable returns false when only others have read (chmod 004)" {
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
}

#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the test_directory function in the editorconfig.awk module.
#
# [FILE] test_directory_test.bats
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
harness="test_directory_harness.awk"

setup_file() {
    log_test_start
}

teardown_file() {
    rmdir -rf "${input}"

    log_test_end
}

#============#
# TEST CASES #
#============#

@test "[TEST] test_directory returns false when empty string is passed" {
    input="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] test_directory returns true when root directory is passed" {
    input="/"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] test_directory returns true when valid directory is passed" {
    input="$(get_temp_working_dir)"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

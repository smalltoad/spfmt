#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the _check_overrides function in the editorconfig.awk module.
#
# [FILE] test_check_overrides.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"

script="editorconfig.awk"
harness="_check_overrides_harness.awk"

setup_file() {
    log_test_start
}

teardown_file() {
    log_test_end
}

@test "[TEST] _check_overrides returns false when both indent size and char are not overriden" {
    vars="indent_size_overriden=0:indent_char_overriden=0"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] _check_overrides returns false when only one of indent size and char are not overriden" {
    vars="indent_size_overriden=1:indent_char_overriden=0"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] _check_overrides returns true when both indent size and char are overriden" {
    vars="indent_size_overriden=1:indent_char_overriden=1"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

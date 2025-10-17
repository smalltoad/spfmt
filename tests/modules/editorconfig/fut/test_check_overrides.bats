#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description: BATS tests for the _check_overrides function in the editorconfig.awk module.
# File: test_check_overrides.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# AWK script containing FUT
script="editorconfig.awk"

# Harness to call specific FUT
harness="_check_overrides_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/check_files_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

@test "_check_overrides returns false when both indent size and char are not overriden" {
    vars="indent_size_overriden=0:indent_char_overriden=0"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "_check_overrides returns false when only one of indent size and char are not overriden" {
    vars="indent_size_overriden=1:indent_char_overriden=0"
    expected="0"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "_check_overrides returns true when both indent size and char are overriden" {
    vars="indent_size_overriden=1:indent_char_overriden=1"
    expected="1"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description:
# BATS tests for the load_config_file function in the editorconfig.awk module.
#
# File: load_config_file_test.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

script="editorconfig.awk"
harness="find_editorconfig_harness.awk"

# Used to set up the mock directory structure for tests.
. "${BATS_TEST_DIRNAME}/../../../bats_helpers/filesystem_setup_helper.bash"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:test_file:test_readable")
    mocked_script=$(basename -- "${mocked_script_path}")
}

setup() {
    # Save base off, input gets modified directly by filesystem_setup_helper.
    base="$(mktemp -d "/tmp/find_editorconfig_test.XXXXXX")"
    export input="${base}"
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END]${BATS_TEST_FILENAME##*/}" >&3
}

teardown() {
    rm -rf "${base:-}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _find_editorconfig edge case of when no input is passed an empty string is returned" {
    input=""
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _find_editorconfig edge case of when root is reached and no config file is found the search terminates" {
    input="/"
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _find_editorconfig returns correct path when file is top level, real and readable" {
    filesystem_setup 0 0 "real_readable"

    expected="${input}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file 1 directory deep, is real and readable" {
    filesystem_setup 1 0 "real_readable"

    expected="${input}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file is very deep in the FS, is real and readable" {
    filesystem_setup 4 0 "real_readable"

    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is real but unreadable" {
    filesystem_setup 3 0 "real"

    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is not a real file" {
    filesystem_setup 3 0 "readable"

    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""
}

@test "[TEST] find_editorconfig returns correct path when file is high in the filesystem, is real and readable" {
    filesystem_setup 3 0 "real_readable"

    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file is deep in the filesystem, is real and readable" {
    filesystem_setup 3 4 "real_readable"

    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

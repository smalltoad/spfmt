#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the load_config_file function in the editorconfig.awk module.
# File: load_config_file_test.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function _find_editorconfig(start_dir,    _curr_path, _file_path_to_check, _cmd_file_check, _is_file, _cmd_read_check, _is_readable, _result, _parent_dir)
# {
#     _curr_path = start_dir
#
#     while (_curr_path != "/" && _curr_path != "") {
#         _file_path_to_check = _curr_path "/.editorconfig"
#
#         _is_file = test_file(_file_path_to_check)
#
#         if (_is_file == 0) {
#             _is_readable = test_readable(_file_path_to_check)
#
#             if (_is_readable == 0) {
#                 return _file_path_to_check
#             }
#         }
#         _parent_dir = get_parent_directory(start_dir)
#
#         if (_parent_dir == start_dir) {
#             return ""
#         }
#
#         _curr_path = _parent_dir
#     }
#
#     return ""
# }

#========#
# SET UP #
#========#

# AWK script containing FUT.
script="editorconfig.awk"

# Harness to call specific FUT.
harness="find_editorconfig_harness.awk"

# Used to set up the mock directory structure for tests.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/filesystem_setup_helper.bash"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:test_file:test_readable")
    mocked_script=$(basename -- "${mocked_script_path}")
}

setup() {
    # All testing directories are based in /tmp folder.
    export input=$(mktemp -d "/tmp/find_editorconfig_test.XXXXXX")
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END]${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] find_editorconfig returns empty string when empty string is passed" {
    input=""
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns empty string when root is passed" {
    input="/"
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file is real and readable" {
    input="${input}/real_readable"
    mkdir "${input}"
    expected="${input}/.editorconfig"
    touch "${expected}"
    env="MOCK_TEST_FILE_RESULT=\"true\" MOCK_TEST_READABLE_RESULT=\"true\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}" \
        -e "${env}"

    rm -rf "${input}"
}

@test "[TEST] find_editorconfig returns correct path when file 1 directory deep, is real and readable" {
    input="${input}/real_readable"
    mkdir "${input}"
    expected="${input}/.editorconfig"
    input="${input}/dummy"
    mkdir "${input}"
    touch "${expected}"
    env="MOCK_TEST_FILE_RESULT=\"true\" MOCK_TEST_READABLE_RESULT=\"true\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}" \
        -e "${env}"

    rm -rf "${input}"
}

@test "[TEST] find_editorconfig returns correct path when file is very deep in the FS, is real and readable" {
    input="${input}/real_readable"
    mkdir "${input}"
    expected="${input}/.editorconfig"
    input="${input}/dummy"
    mkdir "${input}"
    input="${input}/dummy"
    mkdir "${input}"
    input="${input}/dummy"
    mkdir "${input}"
    input="${input}/dummy"
    mkdir "${input}"
    touch "${expected}"
    env="MOCK_TEST_FILE_RESULT=\"true\" MOCK_TEST_READABLE_RESULT=\"true\""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}" \
        -e "${env}"

    rm -rf "${input}"
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is real but unreadable" {
    filesystem_setup 3 0 "real"

    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""

    rm -rf "${input}"
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is not a real file" {
    filesystem_setup 3 0 "readable"

    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""

    rm -rf "${input}"
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

    rm -rf "${input}"
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

    rm -rf "${input}"
}

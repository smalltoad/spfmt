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

# function load_config_file(indent_size, indent_char,    _current_dir, _editorconfig_path, _configs_found, _root_found, _search_flag) {
#     _current_dir = get_current_dir()
#     _search_flag = 1
#     _configs_found = 0
#     _root_found = 0
#
#     while (_search_flag) {
#         _editorconfig_path = _find_editorconfig(_current_dir)
#
#         if (_editorconfig_path != "") {
#             _configs_found += 1
#
#             _parse_editorconfig(_editorconfig_path, indent_size, indent_char)
#
#            if (_is_root_config(_editorconfig_path) == 1) {
#                _current_dir = get_parent_directory()
#            } else {
#                _search_flag = 0
#            }
#         } else {
#             _search_flag = 0
#         }
#     }
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="editorconfig.awk"

# Harness to call specific FUT
harness="load_config_file_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:get_current_dir:_find_editorconfig:_parse_editorconfig:get_parent_directory:_is_root_config")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END]${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] load_config_file with a given root .editorconfig file in the root directory returns the expected values" {
    expected="4:space"
    env="MOCK_CURRENT_DIRECTORY=\"/\" \
        MOCK_FIND_EDITORCONFIG=\"/.editorconfig\" \
        PARSE_EDITORCONFIG_SIZE=\"4\" \
        PARSE_EDITORCONFIG_CHAR=\"space\" \
        IS_ROOT_CONFIG=\"true\" \
        PARENT_DIRECTORY=\"/\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] load_config_file with a given root .editorconfig file in /tmp directory returns the expected values" {
    expected="2:space"
    env="MOCK_CURRENT_DIRECTORY=\"/tmp\" \
        MOCK_FIND_EDITORCONFIG=\"/tmp/.editorconfig\" \
        PARSE_EDITORCONFIG_SIZE=\"2\" \
        PARSE_EDITORCONFIG_CHAR=\"space\" \
        IS_ROOT_CONFIG=\"true\" \
        PARENT_DIRECTORY=\"/tmp\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] [TEST] load_config_file will aggregate multiple .editorconfig files if the first found config file is not root" {
    expected="2:tab"
    env="MOCK_CURRENT_DIRECTORY=\"/tmp/dotfiles\" \
        MOCK_FIND_EDITORCONFIG=\"/tmp/dotfiles/.editorconfig:/tmp/.editorconfig\" \
        PARSE_EDITORCONFIG_SIZE=\"2\" \
        PARSE_EDITORCONFIG_CHAR=\"space:tab\" \
        IS_ROOT_CONFIG=\"false:true\" \
        PARENT_DIRECTORY=\"/tmp/dotfiles\""

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

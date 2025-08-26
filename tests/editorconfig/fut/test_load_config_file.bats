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
#
#     while (_search_flag) {
#         _editorconfig_path = _find_editorconfig(_current_dir)
#
#         if (_editorconfig_path != "") {
#             _configs_found += 1
#
#             _parse_editorconfig(_editorconfig_path, indent_size, indent_char)
#
#            if (_check_is_root(_editorconfig_path) == 1) {
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

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3
}

# Runs for each @test case
setup() {
    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:get_current_dir:_find_editorconfig:_parse_editorconfig:get_parent_directory")
    mocked_script=$(basename -- "${mocked_script_path}")
}

teardown_file() {
    echo "[END]${BATS_TEST_FILENAME##*/}" >&3
}

#============#
# TEST CASES #
#============#

@test "[TEST] generate mock" {
    return 0
}

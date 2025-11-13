#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the load_config_file function in the editorconfig.awk module.
#
# [FILE] load_config_file_test.bats
# [LICESNE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="editorconfig.awk"
harness="load_config_file_harness.awk"

setup_file() {
    log_test_start

    mock=$(mock_script "${script}" "get_current_dir:_find_editorconfig:_parse_editorconfig:get_parent_directory:_is_root_config")
    export mock
}

teardown_file() {
    clean_mock "${mock}"
    log_test_end
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
        -m "${mock}" \
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
        -m "${mock}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] load_config_file will aggregate multiple .editorconfig files if the first found config file is not root" {
    expected="2:tab"
    env="MOCK_CURRENT_DIRECTORY=\"/tmp/dotfiles\" \
        MOCK_FIND_EDITORCONFIG=\"/tmp/dotfiles/.editorconfig:/tmp/.editorconfig\" \
        PARSE_EDITORCONFIG_SIZE=\"2\" \
        PARSE_EDITORCONFIG_CHAR=\"space:tab\" \
        IS_ROOT_CONFIG=\"false:true\" \
        PARENT_DIRECTORY=\"/tmp/dotfiles\""

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -e "${env}" \
        -x "${expected}"
}

@test "[TEST] load_config_file early exits and returns empty string when no path is passed." {
    expected=":"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -x "${expected}"
}

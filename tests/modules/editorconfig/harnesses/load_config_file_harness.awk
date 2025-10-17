#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for editorconfig.awk function of parse_editorconfig to print results.
# File: parse_editorconfig_harness.bats
# License: GNU GPLv3

# Indexes to ENVIRON array to keep track of current return value in ":" delineated list.

{
    CURR_FIND_EDITORCONFIG = 0
    CURR_PARSE_EDITORCONFIG_SIZE = 0
    CURR_PARSE_EDITORCONFIG_CHAR = 0
    CURR_IS_ROOT_CONFIG = 0
    CURR_PARENT_DIRECTORY = 0

    # These must match what is in the _parse_editorconfig function to get set.
    indent_size
    indent_char

    result = load_config_file($0)

    # Printed with ":" deliminter, meant for passing to BATS assertion.
    print indent_size ":" indent_char
}

# Mock function to replace internal get_current_dir().
# Controlled by environment variables in tests, to directly inject a working directory.
function get_current_dir() {
    if (ENVIRON["MOCK_CURRENT_DIRECTORY"]) {
        return ENVIRON["MOCK_CURRENT_DIRECTORY"]
    } else {
        return ""
    }
}

# Mock function to replace internal get_current_dir().
# Controlled by environment variables in tests, to directly inject a working directory.
function _find_editorconfig(_current_dir) {
    if (ENVIRON["MOCK_FIND_EDITORCONFIG"]) {
        count = split(ENVIRON["MOCK_FIND_EDITORCONFIG"], mock_find_editorconfig_array, ":")
        CURR_FIND_EDITORCONFIG += 1
        return mock_find_editorconfig_array[CURR_FIND_EDITORCONFIG]
    } else {
        return ""
    }
}

# Mock function to replace internal get_current_dir().
# Controlled by environment variables in tests, to directly inject a working directory.
function _parse_editorconfig(_editorconfig_path) {
    if (ENVIRON["PARSE_EDITORCONFIG_SIZE"]) {
        count = split(ENVIRON["PARSE_EDITORCONFIG_SIZE"], mock_editorconfig_size_array, ":")
        CURR_PARSE_EDITORCONFIG_SIZE += 1
            if(mock_editorconfig_size_array[CURR_PARSE_EDITORCONFIG_SIZE]) {
            indent_size = mock_editorconfig_size_array[CURR_PARSE_EDITORCONFIG_SIZE]
        }
    }
    if (ENVIRON["PARSE_EDITORCONFIG_CHAR"]) {
        count = split(ENVIRON["PARSE_EDITORCONFIG_CHAR"], mock_editorconfig_char_array, ":")
        CURR_PARSE_EDITORCONFIG_CHAR += 1
        if(mock_editorconfig_char_array[CURR_PARSE_EDITORCONFIG_CHAR]) {
            indent_char = mock_editorconfig_char_array[CURR_PARSE_EDITORCONFIG_CHAR]
        }
    }
}

function _is_root_config(_editorconfig_path) {
    count = split(ENVIRON["IS_ROOT_CONFIG"], mock_is_root_array, ":")
    CURR_IS_ROOT_CONFIG += 1
    if (mock_is_root_array[CURR_IS_ROOT_CONFIG] == "false") {
        return 1 # Return true.
    } else if (mock_is_root_array[CURR_IS_ROOT_CONFIG] == "true") {
        return 0 # Return true.
    } else {
        # Fallback to false if expected environ not found.
        return 1
    }
}

function get_parent_directory() {
    if (ENVIRON["PARENT_DIRECTORY"] ) {
        count = split(ENVIRON["PARENT_DIRECTORY"], mock_parent_dir_array, ":")
        CURR_PARENT_DIRECTORY += 1
        return mock_parent_dir_array[CURR_PARENT_DIRECTORY]
    } else {
        return ""
    }
}

function pop_environ() {

}

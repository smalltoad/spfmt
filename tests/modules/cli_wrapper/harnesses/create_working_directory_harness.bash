#!/bin/bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Test harness for test_create_working_directory.bash
#
# [FILE] create_working_directory_harness.bash
# [LICESNE] GNU GPLv3
# */

#/**
# Sets the TRAP_COMMAND variable based on input.
# Export this variable in calling scope to mock the return value.
# */
add_trap() {
    # shellcheck disable=SC2034 # Exported in calling scope.
    TRAP_COMMAND="$1"
}

#/**
# Returns the MOCK_COMMAND variable.
# Export this variable in calling scope to mock the return value.
# */
command_check() {
    # shellcheck disable=SC2154 # Exported in calling scope.
    return "${MOCK_COMMAND}"
}

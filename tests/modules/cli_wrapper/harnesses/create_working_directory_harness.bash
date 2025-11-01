#!/bin/bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# DESCRIPTION:
# Test harness for test_create_working_directory.bash
#
# FILE: create_working_directory_harness.bash
# LICESNE: GNU GPLv3
# */

#/**
# Sets the TRAP_COMMAND variable based on input.
# export this variable to mock the return value.
# */
add_trap() {
    # shellcheck disable=SC2034 # Exported in calling scope and mutated here.
    TRAP_COMMAND="$1"
}

#/**
# Returns the MOCK_COMMAND variable.
# export this variable to mock the return value.
# */
command_check() {
    # shellcheck disable=SC2154 # Exported in calling scope and mutated here.
    return "${MOCK_COMMAND}"
}

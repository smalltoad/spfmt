#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the handle_c function in the cli_wrapper script.
#
# [FILE] test_handle_c.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

# Source script with FUT and harness.
source_script "cli_wrapper.sh"

setup_file() {
    log_test_start
}

teardown_file() {
    log_test_end
}

#=======#
# TESTS #
#=======#

@test "[TEST] handle_c correctly resolves -c space" {
    handle_c "-c" "space"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${awk_vars}" = "-v indent_char=space " ]] || {
        printf "[ERROR] Indent char was not set as expected."
        return 1
    }
}

@test "[TEST] handle_c correctly resolves -c tab" {
    handle_c "-c" "tab"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${awk_vars}" = "-v indent_char=tab " ]] || {
        printf "[ERROR] Indent char was not set as expected."
        return 1
    }
}

@test "[TEST] handle_c early exits for unexpected indent char" {
    run handle_c "-c" "stab"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Indent char should have not been accepted."
        return 1
    }
}

@test "[TEST] handle_c early exits when the flag but not a flag option is supplied" {
    run handle_c "-c"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Indent char should have not been accepted."
        return 1
    }
}

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

@test "[TEST] handle_s correctly resolves -c space" {
    handle_s "-s" "4"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${awk_vars}" = "-v indent_size=4 " ]] || {
        printf "[ERROR] Indent char was not set as expected."
        return 1
    }
}

#/**
# This is a false-positive passing test, the regex does not detect the negative
# number because it actually is detected as another argument first and thrown
# out. TODO ...something. Not sure what yet. Likely fine as is.
# */
#@test "[TEST] handle_s rejects negative indent sizes" {
#    run handle_s "-s" "-4"
#
#    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
#    [[ "${status}" -eq 2 ]] || {
#        printf "[ERROR] Indent size should have not been accepted."
#        return 1
#    }
#}

@test "[TEST] handle_s early exits for indent size of 0" {
    run handle_s "-s" "0"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Indent size should have not been accepted."
        return 1
    }
}

@test "[TEST] handle_s early exits for unexpected indent size" {
    run handle_s "-s" "four"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Indent size should have not been accepted."
        return 1
    }
}

@test "[TEST] handle_s early exits when the flag but not a flag option is supplied" {
    run handle_s "-s"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Indent size should have not been accepted."
        return 1
    }
}

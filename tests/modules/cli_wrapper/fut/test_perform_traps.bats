#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the preform_trap function in the cli_wrapper script.
#
# [FILE] test_preform_trap.bats
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

@test "[TEST] preform_trap correctly executes when 1 trap is loaded" {
    command="echo"
    text0="Some trap!"
    # shellcheck disable=SC2030 # Intentionally segmented through BATS subshell.
    export traps="${command} ${text0}"

    outputs=$(preform_traps) # Strips final newline

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${outputs}" = "${text0}" ]] || {
        printf "[ERROR] Trap not appended as expected."
        return 1
    }
}

@test "[TEST] preform_trap correctly executes when 2 traps are loaded" {
    command="echo"
    text0="Some trap!"
    text1="Another trap!"
    export traps="${command} ${text0}; ${command} ${text1}"

    outputs=$(preform_traps) # Strips final newline

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    # shellcheck disable=SC3003 # BATS expects Bash interpreter.
    [[ "${outputs}" = "${text0}"$'\n'"${text1}" ]] || {
        printf "[ERROR] Trap not appended as expected.\n"
        printf "%s" "${outputs}"
        return 1
    }
}

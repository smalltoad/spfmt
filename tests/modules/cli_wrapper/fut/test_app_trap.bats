#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the app_trap function in the cli_wrapper script.
#
# [FILE] test_add_traps.bats
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

@test "[TEST] add_trap builds up correctly from 0 traps to 1 trap" {
    new_trap0="Some trap!"

    add_trap "${new_trap0}"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${traps}" = "${new_trap0}" ]] || {
        printf "[ERROR] Trap not appended as expected."
        return 1
    }
}

@test "[TEST] add_trap builds up correctly from 0 traps to 2 traps" {
    new_trap0="Some trap!"
    new_trap1="Some trap2!"

    add_trap "${new_trap0}"
    add_trap "${new_trap1}"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${traps}" = "${new_trap0}; ${new_trap1}" ]] || {
        printf "[ERROR] Trap not appended as expected."
        return 1
    }
}

@test "[TEST] add_trap builds up correctly from 0 traps to many traps" {
    new_trap0="Some trap!"
    new_trap1="This trap!"
    new_trap2="A trap!"

    add_trap "${new_trap0}"
    add_trap "${new_trap1}"
    add_trap "${new_trap2}"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${traps}" = "${new_trap0}; ${new_trap1}; ${new_trap2}" ]] || {
        printf "[ERROR] Trap not appended as expected."
        return 1
    }
}

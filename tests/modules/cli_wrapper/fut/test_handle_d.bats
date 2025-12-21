#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the handle_d function in the cli_wrapper script.
#
# [FILE] test_handle_d.bats
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

@test "[TEST] handle_d correctly counts the amount of d's in a 'd' only string" {
    handle_d "-dd"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_LEVEL}" -eq 2 ]] || {
        printf "[ERROR] Debug level was not set as expected."
        return 1
    }
}

@test "[TEST] handle_d exits if the flag parameter starts with d but has other non-d characters mixed in" {
    run handle_d "-da"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${status}" -eq 2 ]] || {
        printf "[ERROR] Status should be 2."
        return 1
    }
}

@test "[TEST] handle_d enables DEBUG_MODE and sets it to 1 if the DEBUG_LEVEL gets set to 1" {
    handle_d "-d"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_LEVEL}" -eq 1 ]] || {
        printf "[ERROR] Debug level was not set as expected."
        return 1
    }

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_MODE}" -eq 1 ]] || {
        printf "[ERROR] Debug mode was not set as expected."
        return 1
    }
}

@test "[TEST] handle_d enables DEBUG_MODE and DEV_MODE and sets them both to 1 if the DEBUG_LEVEL gets set to 2" {
    handle_d "-dd"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_LEVEL}" -eq 2 ]] || {
        printf "[ERROR] Debug level was not set as expected."
        return 1
    }

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_MODE}" -eq 1 ]] || {
        printf "[ERROR] Debug mode was not set as expected."
        return 1
    }

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEV_MODE}" -eq 1 ]] || {
        printf "[ERROR] Dev mode was not set as expected."
        return 1
    }
}

@test "[TEST] handle_d handles extra d's and increments DEBUG_LEVEL accordingly" {
    handle_d "-ddddd"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_LEVEL}" -eq 5 ]] || {
        printf "[ERROR] Debug level was not set as expected."
        return 1
    }

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEBUG_MODE}" -eq 1 ]] || {
        printf "[ERROR] Debug mode was not set as expected."
        return 1
    }

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${DEV_MODE}" -eq 1 ]] || {
        printf "[ERROR] Dev mode was not set as expected."
        return 1
    }
}

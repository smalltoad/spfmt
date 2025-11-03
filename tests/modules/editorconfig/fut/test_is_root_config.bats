#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the is_root_config function in the editorconfig.awk module.
#
# [FILE] test_is_root_config.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/tmp_folder_helper.bash"

script="editorconfig.awk"
harness="is_root_config_harness.awk"

setup_file() {
    log_test_start
}

setup() {
    # Since each test makes a .editorconfig file, this must not be inside setup_file!
    base="$(get_temp_working_dir)"
    input="${base}/.editorconfig"
    touch "${input}"
}

teardown_file() {
    log_test_end
}

teardown() {
    rm -rf "${base}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _is_root_config returns 1 for empty/null path" {
    input=" "
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for newline path" {
    # shellcheck disable=SC2030 # Intentionally segmented through BATS subshell.
    input="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for empty editorconfig" {
    expected="1"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _is_root_config returns 0 for editorconfig path with only root = 1" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    echo "root = true" >"${input}"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _is_root_config returns 0 and iterates correctly for editorconfig path with some data and root = 1" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "GARBAGE DATA\nroot = true\n" >"${input}"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _is_root_config returns 0 and early exits for editorconfig path with root = 1 and some data" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "root = true\nGARBAGE DATA\n" >"${input}"
    expected="0"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

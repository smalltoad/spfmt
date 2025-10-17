#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the is_root_config function in the editorconfig.awk module.
# File: test_is_root_config.bats
# License: GNU GPLv3
#
# Comandline execution examples:
#     $ bats test_is_root_config.bats
#     $ ./tests/editorconfig/fut/test_is_root_config.bats
# With INFO turned on:
#     $ INFO=1 ./tests/editorconfig/fut/test_is_root_config.bats
# With TAP compliant output:
#     $ bats test_is_root_config.bats --tap

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function _is_root_config(config_file,    line, found_root) {
#     found_root = 0
#
#     while ((getline line < config_file) > 0) {
#         strip_leading_whitespace(line)
#         strip_trailing_whitespace(line)
#
#         if (line == "" || line ~ /^#/) { continue }
#
#         strip_inline_comment(line)
#
#         if (line ~ /^\[.*\]$/) { continue }
#
#         if (tolower(line) ~ /^root[ \t]*=[ \t]*true[ \t]*$/) {
#             found_root = 1
#             break
#         }
#     }
#
#     close(config_file)
#     return found_root
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="editorconfig.awk"

# Harness to call specific FUT
harness="is_root_config_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:strip_leading_whitespace:strip_trailing_whitespace:strip_inline_comment")
    mocked_script=$(basename -- "${mocked_script_path}")
}

setup() {
    base="$(mktemp -d "/tmp/is_root_config_test.XXXXXX")"
    input="${base}"
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

teardown() {
    rm -rf "${base:-}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _is_root_config returns 1 for empty/null path" {
    # Test case that proves robustness, guarding against empty/null input.
    input=" "
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for newline path" {
    # Test case that proves robustness, guarding against empty/null input.
    input="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 1 for empty editorconfig" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 for editorconfig path with only root = 1" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    echo "root = true" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 and loops correctly for editorconfig path with some data and root = 1" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "GARBAGE DATA\nroot = true\n" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _is_root_config returns 0 and early exits for editorconfig path with root = 1 and some data" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "root = true\nGARBAGE DATA\n" >"${input}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

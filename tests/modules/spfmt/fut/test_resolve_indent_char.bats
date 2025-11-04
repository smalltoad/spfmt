#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description: BATS tests for the resolve_indent_char function in the spfmt.awk module.
# File: test_resolve_indent_char.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="spfmt.awk"
harness="resolve_indent_char_harness.awk"

setup_file() {
    log_test_start

    mock=$(mock_script "${script}" "BEGIN:END:REGEX:{}")
    export mock
}

teardown_file() {
    clean_mock "${mock}"
    log_test_end
}

#============#
# TEST CASES #
#============#

@test "[TEST] resolve_indent_char correctly resolves space" {
    vars="indent_char=space"
    expected=" "

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] resolve_indent_char correctly resolves tab" {
    vars="indent_char=tab"
    expected=$(printf "\t")

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] resolve_indent_char does not resolve a bad indent input parameter" {
    vars="indent_char=stab"
    remove='\[ERROR\].*$'
    expected=""

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -v "${vars}" \
        -r "${remove}" \
        -x "${expected}"
}

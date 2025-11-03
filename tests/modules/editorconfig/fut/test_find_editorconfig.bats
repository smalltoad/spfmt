#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the load_config_file function in the editorconfig.awk module.
#
# [FILE] load_config_file_test.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/filesystem_setup_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="editorconfig.awk"
harness="find_editorconfig_harness.awk"

setup_file() {
    log_test_start
}

setup() {
    # Base tmp directory for mock directory strcture to simulate search environment.
    base="$(mktemp -d "/tmp/find_editorconfig_test.XXXXXX")"
}

teardown_file() {
    log_test_end
}

teardown() {
    # Remove all the test scenarios from the base test directory.
    rm -rf "${base}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _find_editorconfig edge case of when no input is passed an empty string is returned" {
    input=""
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _find_editorconfig edge case of when root is reached and no config file is found the search terminates" {
    # shellcheck disable=SC2030 # Intentionally segmented through BATS subshell.
    input="/"
    expected=""

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _find_editorconfig returns correct path when file is top level, real and readable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 0 0 "real_readable" "${base}" || true)
EOF
    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file 1 directory deep, is real and readable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 1 0 "real_readable" "${base}" || true)
EOF
    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file is very deep in the FS, is real and readable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 4 0 "real_readable" "${base}" || true)
EOF
    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is real but unreadable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 3 0 "real" "${base}" || true)
EOF
    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""
}

@test "[TEST] find_editorconfig returns empty string when .editorconfig file is not a real file" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 3 0 "readable" "${base}" || true)
EOF
    touch "${location}/.editorconfig"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x ""
}

@test "[TEST] find_editorconfig returns correct path when file is high in the filesystem, is real and readable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 3 0 "real_readable" "${base}" || true)
EOF
    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] find_editorconfig returns correct path when file is deep in the filesystem, is real and readable" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 3 4 "real_readable" "${base}" || true)
EOF
    expected="${location}/.editorconfig"
    touch "${expected}"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

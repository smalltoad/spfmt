#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/******************************************************************************
# [DESCRIPTION]
# BATS helper for setting up a temp working directory from within BATS tests.
#
# This function very closely mimics the create_working_directory function in
# the CLI wrapper module for spfmt. As this variant is meant to be used inside
# of BATS tests it makes use BATS variables and will fail if not being run from
# a BATS environment!
#
# [FILE] tmp_folder_helper.bash
# [LICENSE] GNU GPLv3
# *****************************************************************************/

# In the event mktemp is not on system.
TMP_DIR_FALLBACK="/tmp"

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME Provided by BATS.
TEST_FILENAME=$(basename -- "${BATS_TEST_FILENAME%.bats}")

get_temp_working_dir() {
    # Try mktemp first, else fall back to PID-based approach.
    if command_check mktemp 2>/dev/null; then
        TMP_DIR=$(mktemp -d -t "spfmt.${TEST_FILENAME}.$$.XXXXXX") || {
            TMP_DIR="${TMP_DIR_FALLBACK}/spfmt.${TEST_FILENAME}.$$.XXXXXX"
            mkdir -p "${TMP_DIR}" 2>/dev/null || {
                printf "[WARNING] mkdir failed? resorting to base /tmp directory.\n"
                TMP_DIR="${TMP_DIR_FALLBACK}" # Reset back to fallback.
            }
        }
    else
        # If mktemp does not exist, resort to fallback.
        printf "[WARNING] Consider installing mktemp for a safer tmp directory.\n"
        TMP_DIR="${TMP_DIR_FALLBACK}/spfmt.${TEST_FILENAME}.$$.XXXXXX"
        mkdir -p "${TMP_DIR}" 2>/dev/null || {
            printf "[WARNING] mkdir failed? resorting to base /tmp directory.\n"
            TMP_DIR="${TMP_DIR_FALLBACK}" # Reset back to fallback.
        }
    fi

    # Trap whichever directory gets selected at the end.
    # add_trap "rm -rf '${TMP_DIR}'"
    echo "${TMP_DIR}"
}

# Wrapper to help with mocking the command builtin.
command_check() {
    ret="$(command -v -- "$1" 2>/dev/null || :)"
    if [[ -n "${ret}" ]]; then
        return 0
    fi
    return 1
}

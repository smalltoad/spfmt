#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the create_working_directory function in the cli_wrapper script.
# File: test_check_overrides.bats
# License: GNU GPLv3

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# create_working_directory() {
#     if command -v mktemp >/dev/null 2>&1; then
#         TMP_DIR=$(mktemp -d -t "spfmt.$$.XXXXXX") || {
#             mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null
#         }
#     else
#         TMP_DIR=$(mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null)
#     fi
#
#     add_trap "rm -rf '${TMP_DIR}'"
# }

#========#
# SET UP #
#========#

# File containing FUT
script="${BATS_TEST_DIRNAME}/../../../src/cli_wrapper.sh"

# Harness to call specific FUT
harness="../harnesses/create_working_directory_harness.bats"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

setup() {
    . "${script}"

    add_trap() {
        TRAP_COMMAND="$1"
        echo "[DEBUG] add_trap called with: $1" >&3
    }
}

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    cat >"${BATS_TEST_DIRNAME}/../tmp/mktemp" <<'EOF'
#!/bin/bash

# Happy path where mktemp is on system and worked
if [ "${MOCK_PATH}" -eq 1 ]; then
    echo ./tmp/path_1
    exit 0
# Middle path where mktemp is on system and failed
elif [ "${MOCK_PATH}" -eq 2 ]; then
    echo ./tmp/path_2
    exit 0
# Abnormal path where mktemp is not on system
elif [ "${MOCK_PATH}" -eq 3 ]; then
    echo ./tmp/path_3
    exit 0
fi
exit 1

EOF

    chmod +x "${BATS_TEST_DIRNAME}/../tmp/mktemp"

    # Prepend mock directory to PATH
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp):$PATH"
}

teardown_file() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

@test "create_working_directory creates the perfered working dir when mktemp is present and works" {
    export MOCK_PATH=1

    # Not using run key word intentionally. Allows for variable capture.
    create_working_directory

    echo "TMP_DIR: $TMP_DIR" >&3

    # Verify TMP_DIR was set to what our mock returned
    [ "${TMP_DIR}" = "./tmp/path_1" ]

    # Verify the trap was added for cleanup
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]]

}

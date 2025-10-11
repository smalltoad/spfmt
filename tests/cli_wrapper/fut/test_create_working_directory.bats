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

# Boilerplate load to get helper with known paths.
load "$(realpath "${BATS_TEST_DIRNAME}/../../../tests/bats_helpers")/sourcing_test_helper.bash"

source_script "cli_wrapper.sh"
source_harness "create_working_directory_harness.bash"

setup_file() {
    log_test_start

    # Mock mktemp binary that gets added to path.
    cat >"${BATS_TEST_DIRNAME}/../tmp/mktemp" <<'EOF'
#!/bin/bash

# Happy path where mktemp is on system and worked
if [ "${MOCK_MKTEMP}" -eq 1 ]; then
    echo ./tmp/path_1
    exit 0
# Middle path where mktemp is on system but failed
elif [ "${MOCK_MKTEMP}" -eq 2 ]; then
    exit 1
# Abnormal path where mktemp is not on system
elif [ "${MOCK_MKTEMP}" -eq 3 ]; then
    exit 1
fi
exit 1

EOF

    # Mock command binary that gets added to path.
    cat >"${BATS_TEST_DIRNAME}/../tmp/command" <<'EOF'
#!/bin/bash

# Happy path where the binary is on path
if [ "${MOCK_COMMAND}" -eq 1 ]; then
    exit 0
fi
# Abnormal path where BINARY is not on system
exit 1

EOF

    chmod +x "${BATS_TEST_DIRNAME}/../tmp/mktemp"
    chmod +x "${BATS_TEST_DIRNAME}/../tmp/command"
}

teardown_file() {
    log_test_end
}

@test "create_working_directory creates the perfered working dir when mktemp is present and works" {
    export MOCK_COMMAND=1 # command finds mktemp
    export MOCK_MKTEMP=1  # mktemp returns 0
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp):$PATH"

    # Not using run key word intentionally. Allows for variable capture.
    create_working_directory || return 1

    # Verify TMP_DIR was set to what our mock returned
    [[ "${TMP_DIR}" = *"./tmp/path_1"* ]] || {
        printf "[FAIL] Unexpected path %s returned from mktemp" "${TMP_DIR}"
        return 1
    }

    # Verify the trap was added for cleanup
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]] || {
        printf "[FAIL] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

@test "create_working_directory results to fallback when mktemp is present but fails" {
    export MOCK_COMMAND=1 # command finds mktemp
    export MOCK_MKTEMP=2  # mktemp returns non-zero
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp):$PATH"

    create_working_directory || return 1

    [[ "${TMP_DIR}" = "/var/tmp/spfmt."* ]] || {
        printf "[FAIL] Unexpected path %s returned from mktemp" "${TMP_DIR}"
        return 1
    }

    # Verify the trap was added for cleanup
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]] || {
        printf "[FAIL] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

@test "create_working_directory results to fallback when mktemp is unavailable" {
    export MOCK_COMMAND=1 # command can't find mktemp
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp):$PATH"

    create_working_directory || return 1

    [[ "${TMP_DIR}" = "/var/tmp/spfmt."* ]] || {
        printf "[FAIL] Unexpected path %s returned from mktemp." "${TMP_DIR}"
        return 1
    }

    # Verify the trap was added for cleanup
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]] || {
        printf "[FAIL] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

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

# Happy path where mktemp workeds
if [[ "${MOCK_MKTEMP}" -eq 1 ]]; then
    echo ./tmp/path_1
    exit 0
# Abnormal path where mktemp is not on system
elif [[ "${MOCK_MKTEMP}" -eq 2 ]]; then
    exit 1
fi

exit 1

EOF

    # Mock mkdir binary that gets added to path.
    cat >"${BATS_TEST_DIRNAME}/../tmp/mkdir" <<'EOF'
#!/bin/bash

# Happy path where mkdir works
if [[ "${MOCK_MKDIR}" -eq 1 ]]; then
    echo "[MOCK MKDIR] Returning pass" >&2
    exit 0
# Abnormal path where mkdir fails
elif [[ "${MOCK_MKDIR}" -eq 2 ]]; then
    echo "[MOCK MKDIR] Returning failure" >&2
    exit 1
fi

exit 1

EOF

    chmod +x "${BATS_TEST_DIRNAME}/../tmp/mktemp"
    chmod +x "${BATS_TEST_DIRNAME}/../tmp/mkdir"
}

teardown_file() {
    log_test_end
}

@test "create_working_directory creates the perfered working dir when mktemp is present and succeeds" {
    export MOCK_MKTEMP=1 # mktemp returns 0.
    export MOCK_MKDIR=1  # mkdir returns 0.
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp):$PATH"

    # Not using run key word intentionally. Allows for variable capture.
    create_working_directory || return 1

    # Verify TMP_DIR was set to what our mock returned.
    [[ "${TMP_DIR}" = "./tmp/path_1" ]] || {
        printf "[FAIL] Unexpected path %s returned from mktemp" "${TMP_DIR}"
        return 1
    }

    # Verify the trap was added for cleanup.
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]] || {
        printf "[FAIL] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

@test "create_working_directory resorts to /var/tmp/spfmt when mktemp is present but fails" {
    export MOCK_MKTEMP=2 # mktemp returns non-zero.
    export MOCK_MKDIR=1  # mkdir returns 0.
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

@test "create_working_directory resorts to /var/tmp/spfmt when mktemp is unavailable and mkdir succeeds" {
    export MOCK_MKDIR=1 # mkdir returns zero.
    # Remove mktemp from path so command can't find it.
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

@test "create_working_directory resorts to /tmp when mktemp is unavailable and mkdir fails" {
    export MOCK_MKDIR=2 # mkdir returns non-zero.
    # Remove mktemp from path so command can't find it.
    export PATH="$(realpath ${BATS_TEST_DIRNAME}/../tmp)"
    create_working_directory || return 1

    [[ "${TMP_DIR}" = "/tmp" ]] || {
        printf "[FAIL] Unexpected path %s returned from mktemp." "${TMP_DIR}"
        return 1
    }

    # Verify the trap was added for cleanup
    [[ "$TRAP_COMMAND" == *"$TMP_DIR"* ]] || {
        printf "[FAIL] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

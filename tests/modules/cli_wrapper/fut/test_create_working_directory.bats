#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the create_working_directory function in the cli_wrapper script.
#
# [FILE] test_check_overrides.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

# Source script with FUT and harness.
source_script "cli_wrapper.sh"
source_harness "create_working_directory_harness.bash"

setup_file() {
    log_test_start

    # Mock mktemp binary that gets added to path for tests that need it.
    cat >"$(get_tmp_dir)/mktemp" <<'EOF'
#!/bin/bash

# Happy path where mktemp works and returns zero
if [[ "${MOCK_MKTEMP}" -eq 1 ]]; then
    echo ./tmp/path_1
    exit 0
# Abnormal path where mktemp is not on system
elif [[ "${MOCK_MKTEMP}" -eq 2 ]]; then
    exit 1
fi

exit 1

EOF

    # Mock mkdir binary that gets added to path for tests that need it.
    cat >"$(get_tmp_dir)/mkdir" <<'EOF'
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

#=========#
# ASSERTS #
#=========#

# Asserts that the expected tmp directory was created.
assert_tmp_dir() {
    expected="$1"

    # shellcheck disable=SC2053 # Intentionally unquoted to allow for globbing.
    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${TMP_DIR}" = ${expected} ]] || {
        printf "[INFO] Unexpected path %s returned from mktemp." "${TMP_DIR}"
        return 1
    }
}

# Asserts that the expected trap command was set.
assert_trap_command() {
    TRAP_COMMAND="$1"

    # shellcheck disable=SC3010 # BATS expects Bash interpreter.
    [[ "${TRAP_COMMAND}" = *"${TMP_DIR}"* ]] || {
        printf "[INFO] Unexpected path %s trapped." "${TMP_DIR}"
        return 1
    }
}

#=======#
# TESTS #
#=======#

@test "[TEST] create_working_directory creates the perfered working dir when mktemp is present and succeeds" {
    # shellcheck disable=SC2030 # Intentionally segmented through BATS subshell.
    {
        export MOCK_MKTEMP=1
        export MOCK_MKDIR=1
        export MOCK_COMMAND=0
        PATH="$(get_tmp_dir):${PATH}"
    }

    #/**
    # Not using run key word intentionally.
    # Allows for variable capture into exported variables.
    # */
    create_working_directory || return 1

    assert_tmp_dir "./tmp/path_1"
    assert_trap_command "${TRAP_COMMAND}"
}

@test "[TEST] create_working_directory resorts to /var/tmp/spfmt when mktemp is present but fails" {
    # Intentionally segmented through BATS subshell.
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    {
        export MOCK_MKTEMP=2 # mktemp returns non-zero.
        export MOCK_MKDIR=1  # mkdir returns 0.
        export MOCK_COMMAND=0
        PATH="$(get_tmp_dir):${PATH}"
    }

    create_working_directory || return 1

    assert_tmp_dir "/var/tmp/spfmt.*"
    assert_trap_command "${TRAP_COMMAND}"
}

@test "[TEST] create_working_directory resorts to /tmp when mktemp is present but fails and mkdir fails" {
    # Intentionally segmented through BATS subshell.
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    {
        export MOCK_MKTEMP=2 # mktemp returns non-zero.
        export MOCK_MKDIR=2  # mkdir returns 0.
        export MOCK_COMMAND=0
        PATH="$(get_tmp_dir):${PATH}"
    }

    create_working_directory || return 1

    assert_tmp_dir "/tmp"

    assert_trap_command "${TRAP_COMMAND}"
}

@test "[TEST] create_working_directory resorts to /var/tmp/spfmt when mktemp is unavailable and mkdir succeeds" {
    # Intentionally segmented through BATS subshell.
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    {
        export MOCK_MKDIR=1
        export MOCK_COMMAND=1
        PATH="$(get_tmp_dir):${PATH}"
    }

    create_working_directory || return 1

    assert_tmp_dir "/var/tmp/spfmt.*"
    assert_trap_command "${TRAP_COMMAND}"
}

@test "[TEST] create_working_directory resorts to /tmp when mktemp is unavailable and mkdir fails" {
    # Intentionally segmented through BATS subshell.
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    {
        export MOCK_MKDIR=2 # mkdir returns non-zero.
        # Remove mktemp from path so command can't find it.
        PATH="$(get_tmp_dir):${PATH}"
    }

    create_working_directory || return 1

    assert_tmp_dir "/tmp"
    assert_trap_command "${TRAP_COMMAND}"
}

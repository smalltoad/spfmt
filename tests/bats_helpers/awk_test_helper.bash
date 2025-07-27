#!/usr/bin/env sh

# File:awk_test_helper.bash
# Desc: BATS helper for AWK testing, streamlines project test creation and assertions.
# Author: Joseph Mowery <mowery.joseph@outlook.com>
# Usage: assert_awk_output script.awk harness.awk test_input expected_output

#=========#
# GLOBALS #
#=========#

# Turns on INFO prints, disabled by default.
#   INFO=${INFO:-0}

# DIRECTIVE JUSTIFICATION: Will inherit BATS env (otherwise script is being used incorrectly.)
# shellcheck disable=SC2154
load "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

#=============#
# AWK ASSERTS #
#=============#

assert_awk() {
    # Assign arguments
    script_name="$1"
    wrapper_name="$2"
    expected="$3"

    # Expected source/helper locations.
    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"
    wrapper_path="${BATS_TEST_DIRNAME}/../harnesses/${wrapper_name}"

    # Ensure fixtures
    is_file "${script_path}" || return 1
    is_file "${wrapper_path}" || return 1

    run bash -c "printf "\\n" | gawk -f <(cat '${script_path}' '${wrapper_path}')"

    if [[ "${INFO}" -eq 1 ]]; then
    printf "%s%s[INFO]%s Expected: [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${expected}" >&3
    printf "%s%s[INFO]%s Actual:   [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${output}" >&3
    fi

    # Check status and output from what BATS captures
    bats_status_check && bats_output_check "${expected}"
}

assert_awk_env() {
    # Assign arguments
    script_name="$1"
    wrapper_name="$2"
    expected="$3"
    # Removes the first 3 args, remainder should be env settings.
    shift 3

    # Expected source/helper locations.
    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"
    wrapper_path="${BATS_TEST_DIRNAME}/../harnesses/${wrapper_name}"

    # Ensure fixtures
    is_file "${script_path}" || return 1
    is_file "${wrapper_path}" || return 1

    env_cmd="env"
    for setting in "$@"; do
        env_cmd="${env_cmd} ${setting}"
    done

    run bash -c "printf "\n" | ${env_cmd} awk -f '${script_path}' -f '${wrapper_path}'"

    if [[ "${INFO}" -eq 1 ]]; then
    printf "%s%s[INFO]%s Expected: [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${expected}" >&3
    printf "%s%s[INFO]%s Actual:   [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${output}" >&3
    fi

    # Check status and output from what BATS captures
    bats_status_check && bats_output_check "${expected}"
}

# Execute AWK scripts feeding input via command line.
assert_awk_stdin() {
    # Assign arguments
    script_name="$1"
    wrapper_name="$2"
    input_string="$3"
    expected="$4"

    # Expected source/helper locations.
    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"
    wrapper_path="${BATS_TEST_DIRNAME}/../harnesses/${wrapper_name}"

    # Ensure fixtures
    is_file "${script_path}" || return 1
    is_file "${wrapper_path}" || return 1

    # Execute the AWK command, return value gets captured in assert helper.
    run bash -c "printf '%s' '${input_string}' | awk -f '${script_path}' -f '${wrapper_path}'"

    if [[ "${INFO}" -eq 1 ]]; then
        printf "%s%s[INFO]%s Input:    [%q]\n" \
            "${BOLD}" "${BLUE}" "${RESET}" "${input_string}" >&3
        printf "%s%s[INFO]%s Expected: [%q]\n" \
            "${BOLD}" "${BLUE}" "${RESET}" "${expected}" >&3
        printf "%s%s[INFO]%s Actual:   [%q]\n" \
            "${BOLD}" "${BLUE}" "${RESET}" "${output}" >&3
    fi

    # Check status and output from what BATS captures
    bats_status_check && bats_output_check "${expected}"
}

# Execute AWK scripts with a file argument.
asset_awk_file() {
    script_name="$1"
    wrapper_name="$2"
    input_file="$3"

    # Expected source/helper locations.
    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"
    wrapper_path="${BATS_TEST_DIRNAME}/../harnesses/${wrapper_name}"

    # Ensure fixtures
    is_file "${script_path}" || return 1
    is_file "${wrapper_path}" || return 1

    # For file based inputs extra set up these paths are required.
    input_path="${BATS_TEST_DIRNAME}/../test_data/inputs/${input_file}"
    output_path="${BATS_TEST_DIRNAME}/../test_data/outputs/${input_file}"
    expected_path="${BATS_TEST_DIRNAME}/../test_data/expected/${input_file}"

    # Execute the AWK command using file input redirection
    run bash -c "awk -f '${script_path}' -f '${wrapper_path}' '${input_path}' >'${output_path}'"

    diff -q "${expected_path}" "${output_path}" >/dev/null 1>&3

    bats_status_check
}

#=================#
# BATS ASSERTIONS #
#=================#

# NOTE: Assertions must happen in the calling scope of 'run'!

# Checks BATS status var for last command ran
bats_status_check() {
    # Check that AWK exit code is successful first.
    # SURPRESSION REASON: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ "${status}" -eq 0 ] || {
        printf "%s%s[ERROR]%s Exit code was non-zero: [%s]" \
            "${BOLD}" "${RED}" "${RESET}" "${status}" >&2
        return 1
    }
}

# Checks BATS status var of the last command ran
bats_output_check() {
    expected="$1"

    # Check that AWK output matches expectation.
    # SURPRESSION REASON: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ "${output}" == "${expected}" ] || {
        printf "%s%s[ERROR]%s Output did not match expectation.\n" \
            "${BOLD}" "${RED}" "${RESET}" >&2
        return 1
    }
}

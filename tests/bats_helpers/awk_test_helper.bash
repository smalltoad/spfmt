#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description:  BATS helper for AWK testing, streamlines project test creation and assertions.
# File: awk_test_helper.bats
# License: GNU GPLv3

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

assert_builder() {
    # Default values to build AWK command with.
    input="printf \"\\n\" | " # Input into AWK function.
    envs=""                   # ENVIRON process variables.
    awk_command="awk"         # AWK command.
    vars=""                   # Passed environment variables.
    mocks=""                  # Mocked function with FUT and stubs.
    files=""                  # Supporting files if needed.
    harnesses=""              # Harness for testing AWK FUT.
    output=""                 # Output file for stdout redirection.
    expected=""               # Expected return of AWK to compare to.

    # Known locations.
    scripts_location="${BATS_TEST_DIRNAME}/../../../src/"
    wrapper_location="${BATS_TEST_DIRNAME}/../harnesses/"
    output_path="${BATS_TEST_DIRNAME}/../test_data/outputs/"

    # Reset OPTIND to ensure clean argument parsing.
    OPTIND=1

    while getopts "f:m:e:i:o:h:x:v:" opt; do
        case "${opt}" in
            f)
                # Add file to end of command.
                files="${files} -f ${scripts_location}${OPTARG}"
                ;;
            h)
                # Harness to call FUT.
                harnesses="${harnesses} -f ${wrapper_location}${OPTARG}"
                ;;
            m)
                # Expecting format "file:function_to_mock1:function_to_mock2..."
                mock_path=$(mock_script "${OPTARG}")
                mocks="${mocks} -f ${mock_path}"
                ;;
            e)
                # Add envs to start of command.
                envs="${envs} ${OPTARG} "
                ;;
            i)
                # Input through stdin, expeted ":" deliniated list.
                # Gets properly parsed in harness.
                input="printf "%b" '${OPTARG}' | "
                ;;
            o)
                # Output location
                output=" > ${OPTARG}"
                ;;
            x)
                # Expected output
                expected="${OPTARG}"
                ;;
            v)
                # TODO: This breaks the output capture that BATS provides.
                #   Debugs are also captured, perhaps there is a better way to
                #   seperate actual output from debug statements in BATS.
                vars=" -v ${OPTARG}"
                ;;
            \?)
                ;;
            :)
                ;;
            *)
                ;;
        esac
    done

    concat_command="${input}${envs}${awk_command}${vars}${mocks}${harnesses}${files}${output}"

    run bash -c "${concat_command}"

    if [[ "${INFO}" -eq 1 ]]; then
    printf "%s%s[INFO]%s Expected: [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${expected}" >&3
    printf "%s%s[INFO]%s Actual:   [%q]\n" \
        "${BOLD}" "${BLUE}" "${RESET}" "${output}" >&3
    fi

    # Check status and output from what BATS captures
    bats_status_check && bats_output_check "${expected}"
}

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

    run bash -c "printf "\n" | awk -f '${script_path}' '${wrapper_path}'"

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

    run bash -c "printf "\\n" | ${env_cmd} awk -f '${script_path}' -f '${wrapper_path}'"

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
    run bash -c "printf '%s\n' '${input_string}' | awk -f '${script_path}' -f '${wrapper_path}'"

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

#=============#
# MOCK HELPER #
#=============#

mock_script() {
    arguments="$1"
    script_name=${arguments%%:*}
    targets=${arguments#*:}

    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"

    mock_path="${BATS_TEST_DIRNAME}/../tmp/mock_${script_name}"
    touch "${mock_path}"

    sed_command=""

    while :; do
        fn=${targets%%:*}
        sed_command+=" -e '/^function ${fn}/,/^}$/d'"
        remaining=${targets#*:}

        [[ "${remaining}" = "${targets}" ]] && break
        targets=${remaining}
    done

    # Loop through each function name that was passed as an argument and build sed command.
    #for function_name in "$@"; do
    #    sed_command="${sed_command} -e '/^function ${function_name}/,/^}$/d'"
    #done

    eval "sed ${sed_command} '${script_path}'" > "${mock_path}"

    printf "%s\n" "${mock_path}"
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

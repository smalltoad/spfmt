#!/usr/bin/env bash
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
INFO=${INFO:-0}

# DIRECTIVE JUSTIFICATION: Will inherit BATS env (otherwise script is being used incorrectly.)
# shellcheck disable=SC2154
load "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

#=============#
# AWK ASSERTS #
#=============#

assert_builder() {
    # Default values to build AWK command with.
    stdin="printf \"\\n\" | " # Input into AWK function.
    envs=""                   # ENVIRON process variables.
    awk_command="awk"         # AWK command.
    vars=""                   # Passed environment variables.
    mocks=""                  # Mocked function with FUT and stubs.
    files=""                  # Supporting files if needed.
    harnesses=""              # Harness for testing AWK FUT.
    output=""                 # Output file for stdout redirection.
    expected=""               # Expected return of AWK to compare to.
    direct=""                 # Directly append arguments.
    remove=""                 # To filter out of output before assert.
    exit_code=""

    # Known locations.
    scripts_location="${BATS_TEST_DIRNAME}/../../../src/"
    wrapper_location="${BATS_TEST_DIRNAME}/../harnesses/"
    mock_location="${BATS_TEST_DIRNAME}/../tmp/"
    input_path="${BATS_TEST_DIRNAME}/../test_data/inputs/"
    output_path="${BATS_TEST_DIRNAME}/../test_data/outputs/"

    # Reset OPTIND to ensure clean argument parsing.
    OPTIND=1

    while getopts "f:h:m:e:i:o:x:v:s:c:r:" opt; do
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
            #/**
            # * If there is no mock file, then assume parameters passed are
            # * sufficient to make one.
            # */
            #if [[ ! -f "${mock_location}${OPTARG%%:*}" ]]; then
            #    mock_script "${OPTARG}"
            #fi
            mocks="${mocks} -f ${mock_location}${OPTARG}"
            ;;
        e)
            # Add envs to start of command.
            if [[ -z "${envs}" ]]; then
                envs="env ${OPTARG} "
            else
                envs="${envs}${OPTARG} "
            fi
            ;;
        i)
            # Input through stdin, expeted ":" deliniated list.
            # Gets properly parsed in harness.
            #stdin="printf "%b" '${OPTARG}' | "

            stdin="printf '%s' $(printf '%q' "${OPTARG}") | "
            ;;
        o)
            # Output location
            output=" ${input_path}${OPTARG} > ${output_path}${OPTARG}"
            ;;
        x)
            # Expected output
            expected="${OPTARG}"
            ;;
        v)
            # TODO: This breaks the output capture that BATS provides.
            #    Debugs are also captured, perhaps there is a better way to
            #    seperate actual output from debug statements in BATS.
            IFS=':' read -ra var_array <<<"${OPTARG}"
            IFS=' '
            # Process each variable assignment.
            for var_assignment in "${var_array[@]}"; do
                # Skip empty assignments.
                if [[ -n "${var_assignment}" ]]; then
                    vars="${vars} -v ${var_assignment}"
                fi
            done
            ;;
        s)
            # Simple flag/option appending.
            direct="${direct} ${OPTARG}"
            ;;
        c)
            exit_code="${OPTARG}"
            ;;
        r)
            # Expects regex for command 'sed -e /OPTARG/d'
            remove="${OPTARG}"
            ;;
        \?)
            printf "[ERROR] Unsupported option of: -%s" "${OPTARG}" >&2
            ;;
        :)
            printf "[ERROR] Option of -%s requires an argument." "${OPTARG}" >&2
            ;;
        *) ;;
        esac
    done

    concat_command="${stdin}${envs}${awk_command}${vars}${mocks}${harnesses}${files}${direct}${output}"

    # TODO: Remove this line. Is used for testing.
    echo "${concat_command}" >&3

    run bash -c "${concat_command}"

    # Filter out any requested lines from output.
    if [[ -n "${remove}" ]]; then
        output=$(echo "${output}" | sed -e "/${remove}/d")
    fi

    # Check status and output from what BATS captures
    bats_status_check "${exit_code}" && bats_output_check "${expected}"
}

#=============#
# MOCK HELPER #
#=============#

#/**
# * Removes functions from a file. Meant for mocking internal functions.
# * Note that for BATS tests, mocks should be made a single time at the
# * top of the file. Parellelism issues have occured when this option is
# * used incorrectly... Prefer -f over this function to avoid flaky tests.
# *
# * USAGE:
# *      Expects format "file:function_to_mock1:function_to_mock2..."
# */
mock_script() {
    arguments="$1"
    script_name=${arguments%%:*}
    targets=${arguments#*:}

    script_path="${BATS_TEST_DIRNAME}/../../../src/${script_name}"
    # Append  PID to separate mocks in a test suite.
    mock_path="${BATS_TEST_DIRNAME}/../tmp/mock_${script_name}.$$"

    touch "${mock_path}"

    sed_command=""

    while :; do
        fn=${targets%%:*}

        if [[ "${fn}" = "BEGIN" ]]; then
            sed_command+=" -e '/^${fn} /,/^}$/d'"
        elif [[ "${fn}" = "END" ]]; then
            sed_command+=" -e '/^${fn} /,/^}$/d'"
        elif [[ "${fn}" = "REGEX" ]]; then
            sed_command+=" -e '/^\/\^/,/^}$/d'"
        elif [[ "${fn}" = "{}" ]]; then
            sed_command+=" -e '/^{/,/^}$/d'"
        else
            sed_command+=" -e '/^function ${fn}/,/^}$/d'"
        fi

        remaining=${targets#*:}

        [[ "${remaining}" = "${targets}" ]] && break
        targets=${remaining}
    done

    eval "sed ${sed_command} '${script_path}'" >"${mock_path}"

    printf "%s\n" "${mock_path}"
}

#=================#
# BATS ASSERTIONS #
#=================#

# NOTE: Assertions must happen in the calling scope of 'run'!

# Checks BATS status var for last command ran
bats_status_check() {
    expected_status="${1:-0}"

    if [[ "${INFO}" -eq 1 ]]; then
        printf "[INFO] Expected Status: [%q]\n" "${expected_status}" >&3
        printf "[INFO] Actual Status:   [%q]\n" "${status}" >&3
    fi

    # Check that AWK exit code is successful first.
    # SURPRESSION REASON: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ "${status}" -eq "${expected_status}" ] || {
        printf "[ERROR] Exit code was non-zero: [%s]" "${status}" >&2
        return 1
    }
}

# Checks BATS status var of the last command ran
bats_output_check() {
    expected="$1"

    if [[ "${INFO}" -eq 1 ]]; then
        printf "[INFO] Expected Output: [%q]\n" "${expected}" >&3
        printf "[INFO] Actual Output:   [%q]\n" "${output}" >&3
    fi

    # Check that AWK output matches expectation.
    # SURPRESSION REASON: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ "${output}" == "${expected}" ] || {
        printf "[ERROR] Output did not match expectation.\n" >&2
        return 1
    }
}

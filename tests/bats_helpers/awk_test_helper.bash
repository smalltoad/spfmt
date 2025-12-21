#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS helper for AWK testing, streamlines test creation and assertions.
#
# [FILE] awk_test_helper.bats
# [LICENSE] GNU GPLv3
# */

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

# Expected to be passed on cli.
INFO=${INFO:-""}

scripts_location="$(get_src_dir)/"
wrapper_location="$(get_harness_dir)/"
build_location="$(get_build_dir)/"
mock_location="$(get_tmp_dir)/"
input_path="$(get_test_inputs_dir)/"
output_path="$(get_test_outputs_dir)/"

#/**
# Known locations. Relative locations are used to dynamically find
# expected locations during execution.
# */

#=============#
# AWK ASSERTS #
#=============#

assert_builder() {
    # Default values to build AWK command template with.
    stdin="printf \"\\n\" | " # Input into AWK function.
    input=""                  # Used for INFO prints only.
    envs=""                   # ENVIRON process variables.
    awk_command="awk"         # AWK command.
    vars=""                   # Passed environment variables.
    mocks=""                  # Mocked function with FUT and stubs.
    files=""                  # Supporting files if needed.
    build=""                  # Path to build script.
    harnesses=""              # Harness for testing AWK FUT.
    output=""                 # Output file for stdout redirection.
    expected=""               # Expected return of AWK to compare to.
    direct=""                 # Directly append arguments.
    remove=""                 # To filter out of output before assert.
    exit_code=""

    while getopts "f:h:m:e:i:o:x:v:s:c:r:b" opt; do
        case "${opt}" in
        f)
            # Add file to end of command.
            files="${files} -f ${scripts_location}${OPTARG}"
            ;;
        h)
            # Harness to call FUT and expose internals.
            harnesses="${harnesses} -f ${wrapper_location}${OPTARG}"
            ;;
        b)
            # Build flag to specify the combined.awk script.
            build="${build_location} -f ${build_location}/build"
            ;;
        m)
            # Mocks should be constructed in file setup of tests.
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
            #/**
            # Input through stdin, expected ":" delineated list.
            # If needed harnesses should properly tokenize and parse/set values.
            # */
            input=$(printf '%q' "${OPTARG}") # used for INFO prints
            stdin="printf '%s' $(printf '%q' "${OPTARG}") | "
            ;;
        o)
            # Output location, will get compared later to an expected.
            output=" ${input_path}${OPTARG} > ${output_path}${OPTARG}"
            ;;
        x)
            # Expected output.
            expected="${OPTARG}"
            ;;
        v)
            #/**
            # TODO: This breaks the output capture that BATS provides.
            # Debugs are also captured, perhaps there is a better way to
            # seperate actual output from debug statements in BATS.
            # */
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
            # Expect a non-zero exit code.
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

    # Templated final command for AWK script.
    concat_command="${stdin}${envs}${awk_command}${vars}${mocks}${harnesses}${files}${build}${direct}${output}"

    if [[ "${INFO}" -eq 1 ]]; then
        echo "[INFO] Command Used: [${concat_command}]" >&3
    fi

    # Use BATS run and capture status and outputs.
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
# Removes functions from a file. Meant for mocking away internal functions.
# Note that for BATS tests, mocks should be made a single time at the
# top of the file. Parellelism issues have occured when this option is
# used incorrectly...
#
# Make sure to use the clean_mock function below to remove tmp files!
#
# USAGE:
#    Expects arg format "file:function_to_mock1:function_to_mock2..."
# */
mock_script() {
    script_name="$1"
    arguments="$2"

    script_path="${scripts_location}/${script_name}"

    # Append PID to separate mocks in a test suite. This is probably uneeded.
    mock_path="${mock_location}/mock_${script_name}.$$"
    touch "${mock_path}"

    sed_command=""

    while :; do
        # Get a requested function to mock from the ':' delineated list.
        fn=${arguments%%:*}

        # Removes the BEGIN scope from a script
        if [[ "${fn}" = "BEGIN" ]]; then
            sed_command+=" -e '/^${fn} /,/^}$/d'"
        # Removes the END scope from a script
        elif [[ "${fn}" = "END" ]]; then
            sed_command+=" -e '/^${fn} /,/^}$/d'"
        # Removes ALL the regex rules
        elif [[ "${fn}" = "REGEX" ]]; then
            sed_command+=" -e '/^\/\^/,/^}$/d'"
        #/**
        # Removes all basic scopes from a script
        # This is mostly just required for the spfmt.awk module.
        # */
        elif [[ "${fn}" = "{}" ]]; then
            sed_command+=" -e '/^{/,/^}$/d'"
        # Otherwise, just remove the function name from the awk file
        else
            sed_command+=" -e '/^function ${fn}/,/^}$/d'"
        fi

        # Remove the requested function that was just handled from the targets.
        remaining=${arguments#*:}

        # Any targets left?
        [[ "${remaining}" = "${arguments}" ]] && break
        arguments=${remaining}
    done

    eval "sed ${sed_command} '${script_path}'" >"${mock_path}"

    # Just return the mock name, the path is managed in this file.
    printf "%s\n" "$(basename -- "${mock_path}")"
}

# Use this in teardown_file within test files.
clean_mock() {
    rm -rf "${mock_location:?}/$1"
}

#=================#
# BATS ASSERTIONS #
#=================#

# NOTE: Assertions must happen in the calling scope of 'run'!

# Checks BATS status var for last command ran.
bats_status_check() {
    expected_status="${1:-0}"

    if [[ "${INFO}" -eq 1 ]]; then
        printf "[INFO] Expected Status: [%q]\n" "${expected_status}" >&3
        # shellcheck disable=SC2154 # status is captured and provided by BATS.
        printf "[INFO] Actual Status:   [%q]\n" "${status}" >&3
    fi

    [[ "${status}" -eq "${expected_status}" ]] || {
        printf "[ERROR] Exit code was non-zero: [%s]" "${status}" >&2
        return 1
    }
}

# Checks BATS output var of the last command ran.
bats_output_check() {
    expected="$1"

    if [[ "${INFO}" -eq 1 ]]; then
        if [[ -n "${input}" ]]; then
            echo "[INFO] Actual Input:    [${input}]" >&3
        fi
        printf "[INFO] Expected Output: [%q]\n" "${expected}" >&3
        printf "[INFO] Actual Output:   [%q]\n" "${output}" >&3
    fi

    # Check that AWK output matches expectation.
    [[ "${output}" == "${expected}" ]] || {
        printf "[ERROR] Output did not match expectation.\n" >&2
        return 1
    }
}

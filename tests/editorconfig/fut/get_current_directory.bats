#!/usr/bin/env bats

# File: get_current_directory.bats
# Desc: BATS tests for the get_current_directory function in the editorconfig.awk module.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function get_current_dir() {
#     current_dir = ENVIRON["PWD"]
#
#     if (!current_dir || !test_directory(current_dir)) { current_dir = "." }
#
#     return current_dir
# }

#========#
# SET UP #
#========#

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

# Runs for each @test case
setup() {
    # Environment file for BATS
    #env="${BATS_TEST_DIRNAME}/../../../project_env"
    #. "${env}"

    # AWK script containing FUT
    editorconfig_awk_script="editorconfig.awk"

    # Harness to call specific FUT
    editorconfig_awk_harness="get_current_directory_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

#============#
# TEST CASES #
#============#

@test "${MAGENTA}[TEST] get_current_directory returns the correct absolute path${RESET}" {
    # Nominal test case with normal pwd process environ var
    expected_result=$(pwd)

    assert_awk "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}"
}

@test "${MAGENTA}[TEST] get_current_directory returns the "." when pwd is unset${RESET}" {
    # Test case for PWD not set, should return default .
    expected_result="."

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "-u PWD"
}

@test "${MAGENTA}[TEST] get_current_directory handles PWD with only whitespace${RESET}" {
    # Whitespace edge case
    expected_result="."

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "PWD=   "
}

@test "${MAGENTA}[TEST] get_current_directory handles PWD with non-real directory path${RESET}" {
    # Whitespace edge case
    expected_result="."

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "PWD=/not/a/real/file/path/asdfghjkl"
}

@test "${MAGENTA}[TEST] get_current_directory handles PWD as root directory${RESET}" {
    # The root directory edge/special case
    expected_result="/"

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "PWD=/"
}

@test "${MAGENTA}[TEST] get_current_directory handles PWD path ending with slash${RESET}" {
    # Create tmp dir to test is paths with leading slash work
    tmp_dir=$(mktemp -d)
    expected_result="${tmp_dir}/"

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "PWD=${tmp_dir}/"

    rmdir "${tmp_dir}"
}

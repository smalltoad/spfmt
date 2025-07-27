#!/usr/bin/env bats

# File: test_readable.bats
# Desc: BATS tests for the test_readable function in the editorconfig.awk module.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function test_readable(file_to_check, is_readable) {
#     # Test if file exists using test command
#     cmd_read_check = "test -r \"" file_to_check "\""
#     is_readable = system(cmd_read_check)
#
#     return is_readable
# }

#=========#
# GLOBALS #
#=========#

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

#============#
# BATS HOOKS #
#============#

# Runs for each @test case
setup() {
    # Environment file for BATS
    #env="${BATS_TEST_DIRNAME}/../../../project_env"
    #. "${env}"

    # AWK script containing FUT
    editorconfig_awk_script="editorconfig.awk"

    # Harness to call specific FUT
    editorconfig_awk_harness="test_readable_harness.awk"

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

@test "${MAGENTA}[TEST] get_current_directory handles PWD path ending with slash${RESET}" {
    # Create tmp dir to test is paths with leading slash work
    tmp_dir=$(mktemp -d)
    expected_result="${tmp_dir}/"

    assert_awk_env "${editorconfig_awk_script}" "${editorconfig_awk_harness}" "${expected_result}" "PWD=${tmp_dir}/"

    rmdir "${tmp_dir}"
}

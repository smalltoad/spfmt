#!/usr/bin/awk -f

# File: get_current_directory_harness.bats
# Desc: Wrapper for editorconfig.awk function of get_current_directory to print results.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

# Mock function to replace internal test_directory().
# This will be controlled by environment variables in tests.
function test_directory(current_dir) {
    # Mock control environment variable will store literal return result.
    if (ENVIRON["MOCK_TEST_DIRECTORY_RESULT"] == "false") {
        return 0  # Return false (directory doesn't exist).
    } else if (ENVIRON["MOCK_TEST_DIRECTORY_RESULT"] == "true") {
        return 1  # Return true (directory exists).
    } else {
        # Fallback if expected environ not found.
        return 1
    }
}

BEGIN {
    result = get_current_dir()
    print result
}

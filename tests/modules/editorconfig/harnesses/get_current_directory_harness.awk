#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of get_current_directory to print results.
#
# [FILE] get_current_directory_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    result = get_current_dir($0)
    print result
}

#/**
# Mock function to replace internal test_directory().
# Controlled by environment variables in tests, since current dir may or may
# not exist. And since the current dir variable gets used after test_directory.
# */
function test_directory(arg) {
    # Mock control environment variable will store literal return result.
    if (ENVIRON["MOCK_TEST_DIRECTORY_RESULT"] == "false") {
        return 1  # Return false (directory doesn't exist).
    } else if (ENVIRON["MOCK_TEST_DIRECTORY_RESULT"] == "true") {
        return 0  # Return true (directory exists).
    } else {
        # Fallback to false if expected environ not found.
        return 1
    }
}

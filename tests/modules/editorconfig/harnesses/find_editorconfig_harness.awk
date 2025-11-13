#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for file_utils.awk function of test_readable to print results.
#
# [FILE] test_readable_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    result = _find_editorconfig($0)
    print result
}

# If the file name contians the string "real" only then return true.
function test_file(_file_path_to_check) {
    if (_file_path_to_check ~ /.*real.*\/.editorconfig$/) {
        return 0
    }
    return 1
}

# If the file name contians the string "readable" only then return true.
function test_readable(_file_path_to_check) {
    if (_file_path_to_check ~ /.*readable\/.editorconfig$/) {
        return 0
    }
    return 1
}

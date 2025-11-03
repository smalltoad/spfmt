#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for file_utils.awk function of test_file to print results.
#
# [FILE] test_file_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    result = test_file($0)
    print result
}

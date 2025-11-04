#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description: Wrapper for file_utils.awk function of test_readable to print results.
# File: test_readable_harness.bats
# License: GNU GPLv3

{
    result = _value_of_flag($0)
    print result
}

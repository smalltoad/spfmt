#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Wrapper for editorconfig.awk function of get_parent_directory to print results.
# File: get_parent_directory_harness.bats
# License: GNU GPLv3

{
    result = get_parent_directory($0)
    print result
}

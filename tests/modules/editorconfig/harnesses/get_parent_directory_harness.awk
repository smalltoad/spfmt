#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of get_parent_directory to print results.
#
# [FILE] get_parent_directory_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    result = get_parent_directory($0)
    print result
}

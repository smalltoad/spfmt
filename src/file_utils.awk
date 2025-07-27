#!/usr/bin/awk -f

# File: editorconfig.awk
# Description: POSIX-compliant AWK script to load in an .editorconfig file.
# Author: Joseph Mowery <mowery.joseph@outlook.com>
# Usage: awk editorconfig.awk -f parse.awk input_file.sh

#============#
# FILE UTILS #
#============#

# Test if file exists using test command, must be string literal.
function check_file(file_to_check, is_file) {
    cmd_file_check = "test -f \"" file_to_check "\""
    is_file = system(cmd_file_check)

    return is_file
}

# Test if a file is readable, must be string literal.
function test_readable(file_to_check, is_readable) {
    # Test if file exists using test command
    cmd_read_check = "test -r \"" file_to_check "\""
    is_readable = system(cmd_read_check)

    return (is_readable == 0)
}

function test_directory(current_dir) {
    cmd = "test -d \"" current_dir "\""

    # Execute command and capture exit code
    is_directory = system(cmd)

    return (is_directory == 0)
}

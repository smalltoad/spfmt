#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: File tests to support file loading.
# File: file_utils.awk
# License: GNU GPLv3

#=======#
# TESTS #
#=======#

#/**
# * [DESCRIPTION]
# * Wrapper that passes flag 'f' to main test function.
# *
# * @param target {passed}
# *     Target to test against. Should be a path.
# */
function test_file(target) {
    return _test_with_flag(target, "f")
}

#/**
# * [DESCRIPTION]
# * Wrapper that passes flag 'r' to main test function.
# *
# * @param target {passed}
# *     Target to test against. Should be a path.
# */
function test_readable(target) {
    return _test_with_flag(target, "r")
}

#/**
# * [DESCRIPTION]
# * Wrapper that passes flag 'd' to main test function.
# *
# * @param target {passed}
# *     Target to test against. Should be a path.
# */
function test_directory(target) {
    return _test_with_flag(target, "d")
}

#/**
# * [DESCRIPTION]
# * Logic that runs a test in a subshell, taking a passed flag and test target.
# * Returns 1 on failure. Invalid parameters or unsupported flag results in a
# * return values of 1.
# *
# * @param target {passed}
# *     Target to test against. Should be a path.
# *
# * @param flag {passed}
# *     Flag that gets injected into test command. To see which flags are
# *     currently supported see the ENUMS section below.
# *
# * @param _resolved_flag {local}
# *     String value of resolved flag. Used for debug statements and to validate
# *     that the passed flag is supported. Will be an empty string if the flag
# *     is not supported.
# *
# * @param _cmd {local}
# *     String literal of the constructed test command argument.
# *
# * @param _result {local}
# *     Status code of the resulting cmd execution.
# */
function _test_with_flag(target, flag,    _resolved_flag, _cmd, _result) {
    _resolved_flag = _value_of_flag(flag)
    _result = 1 # Until success, assume failiure.

    if (!target || !_resolved_flag) {
        if (DEV_MODE) {
            if(!target) {
                print "[DEBUG] Requires a valid test target to be passed." > "/dev/stderr"
            }
            if(!_resolved_flag) {
                print "[DEBUG] Requires a valid and supported flag to be passed." > "/dev/stderr"
            }
        }
        return _result
    }

    # Execute command and capture exit code
    _cmd = "test -"flag"  \"" target "\""
    if (DEV_MODE) {
        print "[DEBUG] cmd command to execute is: " _cmd > "/dev/stderr"
    }
    _result = system(_cmd)

    if (DEV_MODE) {
        print "[DEBUG] Result of cmd command was: " _result > "/dev/stderr"
    }

    if (DEV_MODE) {
        if (_result == 0) {
            print "[DEBUG] Path " target " is " _resolved_flag "." > "/dev/stderr"
        } else {
            print "[DEBUG] Path " target " is not " _resolved_flag "." > "/dev/stderr"
        }
    }

    return (_result)
}

#========#
# ENUMS? #
#========#

#/**
# * [DESCRIPTION]
# * Pseudo-enum like function that both returns a string value for print outs
# * and acts as validation to check if a flag is supported.
# *
# * @param flag {passed}
# *     Flag to resolve.
# *
# * @param _FILE {local}
# *     File enum, expects a lowercase f.
# *
# * @param _READABLE {local}
# *     File enum, expects a lowercase r.
# *
# * @param _DIRECTORY {local}
# *     File enum, expects a lowercase d.
# *
# * @param _resolved_flag {local}
# *     Result and return of the resolved flag. Matches the string in the
# *     if-else statement. Returns "" if the passed flag matches nothing.
# */
function _value_of_flag(flag,    _FILE, _READABLE, _DIRECTORY, _resolved_flag) {
    _FILE = "f"
    _READABLE = "r"
    _DIRECTORY = "d"

    _resolved_flag = ""

    if (flag == _FILE) {
        return "file"
    } else if (flag == _READABLE) {
        return "readable"
    } else if (flag == _DIRECTORY) {
        return "directory"
    }

    if(DEV_MODE) {
        print "[DEBUG] Flag \"" flag "\" is unsupported or malformed." > "/dev/stderr"
    }

    # Return empty string for unsupported flags or a malformed flag.
    return _resolved_flag
}

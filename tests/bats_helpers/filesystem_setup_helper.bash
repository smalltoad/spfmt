#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS helper for setting up file structures to form different testing scenarios.
#
# [FILE] filesystem_setup_helper.bash
# [LICENSE] GNU GPLv3
# */

#/**
# [DESCRIPTION]
# Targeted helper in test_find_editorconfig.bats to set up a mock filesystem.
#
# @param $1 {integer}
#     How many directories to seed before the target location.
#
# @param $2 {integer}
#     How many directories to seed after the target location.
#
# @param $3 {string}
#     Name of the file file to place in target location.
#
# @param $4 {path}
#     Base directory .
#
# @return location {path}
#     The path that the test should expect the location at.
#
# USAGE:
#    filesystem_setup 3 4 "filename" # 3 deep and 4 above, file name real_readable
#    filesystem_setup 1 0 "filename" # 1 deep and 0 above, file name readable
#    filesystem_setup 1 0 "filename" "/tmp" # base dir is optional
# */
filesystem_setup() {
    before="$1"
    after="$2"
    #/**
    # Where the test target lives, should be an actual name.
    # Look at the test/harness for find_editorconfig for more examples.
    # */
    target="$3"
    base="$4"

    # Build up the directories before where .editorconfig lives.
    input="${base}" # prepend base dir.
    for ((i = 0; i < "${before}"; i++)); do
        input="${input}/dummy"
        mkdir "${input}"
    done

    #/**
    # Create folder that will house .editorconfig, NOTE that naming should matter!
    # Test harnesses (such as find_editorconfig_harness.awk) should have logic to
    # pass/fail bases on some hint in the file name.
    # */
    input="${input}/${target}"
    mkdir "${input}"

    # Save off location early.
    location="${input}"

    # Build up the directories before where .editorconfig lives.
    for ((i = 0; i < "${after}"; i++)); do
        input="${input}/dummy"
        mkdir "${input}"
    done

    # location - Expected location, caller needs to make the file here.
    # input - Full constructed path.
    echo "${location}:${input}"
}

#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS helper for setting up file structures to form different testing scenarios.
# File: filesystem_setup_helper.bash
# License: GNU GPLv3

# Targeted helper in test_find_editorconfig.bats to set up a mock filesystem.
filesystem_setup() {
    before="$1" # Integer.
    after="$2"  # Integer.
    target="$3" # Where the test target lives, should be an actual name.

    # Build up the directories before where .editorconfig lives.
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

    # Exposes location to append required files.
    location="${input}"

    # Build up the directories before where .editorconfig lives.
    for ((i = 0; i < "${after}"; i++)); do
        input="${input}/dummy"
        mkdir "${input}"
    done
}

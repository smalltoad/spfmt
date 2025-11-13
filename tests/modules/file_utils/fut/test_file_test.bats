#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description:  BATS tests for the test_file function in the editorconfig.awk module.
# File: test_file_test.bats
# License: GNU GPLv3

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/tmp_folder_helper.bash"

script="file_utils.awk"
harness="test_file_harness.awk"

setup_file() {
    log_test_start

    tmp_dir="$(get_temp_working_dir)"
    export tmp_dir

    tmp_file="${tmp_dir}/tmp_file"
    touch "${tmp_file}"
    export tmp_file
}

setup() {
    # Get unique name but dosen't create file.
    # If a file is created this identifier should be used so it is cleaned up.
    unique=$(mktemp -u --suffix=".$$")
    export unique
}

teardown_file() {
    rm -rf "${tmp_file}" "${tmp_link}" "${tmp_dir}" "${test_socket}" "${tmp_fifo}" "${unique}"

    log_test_end
}

#============#
# TEST CASES #
#============#

# **/
# [TEST DOMAIN]
#     Regular files   (-)
#     Directories     (d)
#     Symlinks        (l)
#     Char devices    (c)
#     Block devices   (b)
#     FIFO/named pipe (p)
#     Sockets         (s)
# */

@test "[TEST] test_file returns true when target is a normal file (-)" {
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

}

@test "[TEST] test_file returns false when target is a directory (d)" {
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_dir}" \
        -x "${expected}"
}

@test "[TEST] test_file returns true for symlink pointing to regular file (l)" {
    ln -s "${tmp_file}" "${unique}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false for symlink pointing to directory (l)" {
    ln -s "${tmp_dir}" "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false for broken symlink (l)" {
    fake="${unique}.nonexistent"
    ln -s "${fake}" "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false for named pipe (FIFO)" {
    mkfifo "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false for character device (c)" {
    # /dev/null is a character device that should exist on all Unix-like systems.
    target="/dev/null"
    expected="1"

    # Only run if /dev/null exists.
    if [ -c "${target}" ]; then
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "Character device /dev/null not available"
    fi
}

@test "[TEST] test_file returns false for block device (b)" {
    # Reason: This is a BATS test, access to bash is guarenteed.
    # shellcheck disable=SC3030
    block_locations=(
        /dev/sda
        /dev/sda1
        /dev/disk0
        /dev/loop0
    )

    target=""
    expected="1"

    # Try to find a block device from common locations.
    # shellcheck disable=SC3054 # Bash interpreter used in BATS
    for device in "${block_locations[@]}"; do
        if [ -b "${device}" ]; then
            target="${device}"
            break
        fi
    done

    if [ -n "${target}" ]; then
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "No accessible block device found for testing"
    fi
}

@test "[TEST] test_file returns false for Unix domain socket (s)" {
    # Create a unique socket path using PID to avoid conflicts in parallel runs
    test_socket="/tmp/test_socket_$$_${BATS_TEST_NUMBER}"
    expected="1" # test_file should return false for sockets

    # Create a Unix domain socket using socat (if available) or netcat
    # We'll run this in background and clean it up regardless of test outcome
    if command -v socat >/dev/null 2>&1; then
        # socat creates a socket and keeps it open
        socat UNIX-LISTEN:"${test_socket}",fork /dev/null &
        socket_pid=$!

        # Give socat a moment to create the socket
        sleep 0.1

        # Verify the socket was created
        if [ -S "${test_socket}" ]; then
            assert_builder \
                -f "${script}" \
                -h "${harness}" \
                -i "${test_socket}" \
                -x "${expected}"
        else
            skip "Failed to create test socket with socat"
        fi

        # Clean up: kill socat and remove socket
        kill "${socket_pid}" 2>/dev/null || true
        rm -f "${test_socket}"

    elif command -v nc >/dev/null 2>&1; then
        # Alternative using netcat (though less reliable for this purpose)
        nc -lU "${test_socket}" &
        socket_pid=$!
        sleep 0.1

        if [ -S "${test_socket}" ]; then
            assert_builder \
                -f "${script}" \
                -h "${harness}" \
                -i "${test_socket}" \
                -x "${expected}"
        else
            skip "Failed to create test socket with netcat"
        fi

        kill "${socket_pid}" 2>/dev/null || true
        rm -f "${test_socket}"

    else
        skip "Neither socat nor netcat available for creating test socket"
    fi
}

@test "[TEST] test_file returns false for non-existent file" {
    # Use a path that's very unlikely to exist.
    target="/this/path/should/not/exist/$(date +%s%N)"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${target}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false for empty string" {
    target="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${target}" \
        -x "${expected}"
}

@test "[TEST] test_file handles file with no read permissions (-)" {
    tmp_file=$(mktemp --suffix=".$$")
    chmod 000 "${tmp_file}" # Remove all permissions
    expected="0"            # Should still be detected as a file, even if unreadable

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
}

@test "[TEST] test_file handles path with spaces (-)" {
    tmp_file=$(mktemp --suffix=" with spaces.$$")
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"
}

@test "[TEST] test_file handles path with special characters (-)" {
    # Create file with special characters (be careful with shell metacharacters)
    tmp_dir=$(mktemp -d --suffix=".$$")
    tmp_file="${tmp_dir}/file-with_special.chars@123"
    touch "${tmp_file}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"
}

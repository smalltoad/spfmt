#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the test_file function in the editorconfig.awk module.
#
# [FILE] test_file_test.bats
# [LICENSE] GNU GPLv3
# */

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
    #/**
    # Get unique name but doesn't create file.
    # Only used in some tests.
    # */
    unique=$(mktemp -u --suffix=".$$")
    export unique
}

teardown_file() {
    # tmp_file lives in tmp_dir, should not need to be explicitly removed.
    rm -rf "${tmp_dir}" "${tmp_link}" "${test_socket}" "${tmp_fifo}" "${unique}"

    log_test_end
}

teardown() {
    rm -rf "${unique}"
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
#     FIFO/Named pipe (p)
#     Sockets         (s)
# */

@test "[TEST] test_file returns true when target is a real regular file (-)" {
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

}

@test "[TEST] test_file returns false when target is a non-real regular file (-)" {
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "/not-a-real-file.$$.txt" \
        -x "${expected}"

}

@test "[TEST] test_file returns false when target is a real directory (d)" {
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_dir}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false when target is a non-real directory (d)" {
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_dir}/not-a-real-dir.$$" \
        -x "${expected}"
}

@test "[TEST] test_file returns true when target is a symlink pointing to regular file (l)" {
    ln -s "${tmp_file}" "${unique}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false when target is a symlink pointing to directory (l)" {
    ln -s "${tmp_dir}" "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false when target is a broken symlink (l)" {
    fake="${unique}.nonexistent"
    ln -s "${fake}" "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false when target is a named pipe (FIFO)" {
    mkfifo "${unique}"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${unique}" \
        -x "${expected}"
}

@test "[TEST] test_file returns false when target is a character device (c)" {
    # shellcheck disable=SC3030 # BATS expects Bash interpreter.
    char_locations=(
        /dev/null
        /dev/random
        /dev/urandom
    )

    # Try to find a char device from common locations.
    # shellcheck disable=SC3054 # BATS expects Bash interpreter.
    for device in "${char_locations[@]}"; do
        if [ -c "${device}" ]; then
            target="${device}"
            break
        fi
    done

    expected="1"

    # Only run if /dev/null exists.
    if [ -n "${target}" ]; then
        assert_builder \
            -f "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "No accessible char device found for testing"
    fi
}

@test "[TEST] test_file returns false when target is a block device (b)" {
    # shellcheck disable=SC3030 # BATS expects Bash interpreter.
    block_locations=(
        /dev/sda
        /dev/sda1
        /dev/disk0
        /dev/loop0
    )

    target=""
    expected="1"

    # Try to find a block device from common locations.
    # shellcheck disable=SC3054 # BATS expects Bash interpreter.
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

@test "[TEST] test_file returns false when target is a Unix domain socket (s)" {
    test_socket="${unique}"
    expected="1" # test_file should return false for sockets.

    # Create a Unix domain socket using socat (if available) or netcat.
    if command -v socat >/dev/null 2>&1; then
        #/**
        # socat creates a socket and keeps it open
        #     UNIX-LISTEN:     - Create a UDS in listen mode
        #     "${test_socket}" - The FS path to were the socket will be created.
        #     fork             - Fork a new process for each new connection.
        #     /dev/null        - Send data to the ether.
        # */
        socat UNIX-LISTEN:"${test_socket}",fork /dev/null &
        socket_pid=$! # UDS PID required for clean up!

        # Poll for socket creation with timeout.
        timeout=20
        while [ "${timeout}" -gt 0 ] && [ ! -S "${unique}" ]; do
            # Can the process be signaled? If not then it has died.
            if ! kill -0 "${socket_pid}" 2>/dev/null; then
                skip "socat process died before creating socket"
            fi
            sleep 0.1
            timeout=$((timeout - 1))
        done

        # Verify the socket was created.
        if [ -S "${test_socket}" ]; then
            assert_builder \
                -f "${script}" \
                -h "${harness}" \
                -i "${test_socket}" \
                -x "${expected}"
        else
            skip "Failed to create test socket with socat, possible socket creation timeout."
        fi

        # Clean up, kill socat and remove socket.
        kill "${socket_pid}" 2>/dev/null || true
        rm -f "${test_socket}"

    elif command -v nc >/dev/null 2>&1; then
        # Alternative approach using netcat.
        nc -lU "${test_socket}" &
        socket_pid=$!

        # Poll for socket creation with timeout.
        timeout=20
        while [ "${timeout}" -gt 0 ] && [ ! -S "${unique}" ]; do
            # Can the process be signaled? If not then it has died.
            if ! kill -0 "${socket_pid}" 2>/dev/null; then
                skip "socat process died before creating socket"
            fi
            sleep 0.1
            timeout=$((timeout - 1))
        done

        if [ -S "${test_socket}" ]; then
            assert_builder \
                -f "${script}" \
                -h "${harness}" \
                -i "${test_socket}" \
                -x "${expected}"
        else
            skip "Failed to create test socket with netcat, possible socket creation timeout."
        fi

        kill "${socket_pid}" 2>/dev/null || true
        rm -f "${test_socket}"

    else
        skip "Neither socat nor netcat available for creating test socket"
    fi
}

@test "[TEST] test_file returns false for newline" {
    target="\n"
    expected="1"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${target}" \
        -x "${expected}"
}

@test "[TEST] test_file handles returns false when target is a real regular file with no read permissions (-)" {
    chmod 000 "${tmp_file}" # Remove all permissions
    expected="0"            # Should still be flagged as a file, even if unreadable.

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
}

@test "[TEST] test_file returns false when target is a real regular file with spaces in the name (-)" {
    new_path="${tmp_dir}/ with  spaces   "
    touch "${new_path}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${new_path}" \
        -x "${expected}"
}

@test "[TEST] test_file handles path with special characters (-)" {
    new_path="${tmp_dir}/file-with_special.chars?@123!@#$%^%&*()"
    touch "${new_path}"
    expected="0"

    assert_builder \
        -f "${script}" \
        -h "${harness}" \
        -i "${new_path}" \
        -x "${expected}"

}

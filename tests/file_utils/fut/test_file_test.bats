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

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# NOTE: This function is a wrapper around _test_with_flag, for implementation
# details refer to either file_utils._test_with_flag or test_with_flag_test.bats

# function test_file(target, flag) {
#     return _test_with_flag(target, "f")
# }

#========#
# SET UP #
#========#

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

# Runs for each @test case
setup() {
    # AWK script containing FUT
    script="file_utils.awk"

    # Harness to call specific FUT
    harness="test_file_harness.awk"

    # BATS helpers
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
    load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"
}

#============#
# TEST CASES #
#============#

# **/
# * [TEST DOMAIN]
# *     Regular files   (-)
# *     Directories     (d)
# *     Symlinks        (l)
# *     Char devices    (c)
# *     Block devices   (b)
# *     FIFO/named pipe (p)
# *     Sockets         (s)
# */

@test "${MAGENTA}[TEST] test_file returns true when target is a normal file (-)${RESET}" {
    tmp_file=$(mktemp)
    expected="0"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "${MAGENTA}[TEST] test_file returns false when target is a directory (d)${RESET}" {
    tmp_dir=$(mktemp -d)
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_dir}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
}

@test "${MAGENTA}[TEST] test_file returns true for symlink pointing to regular file (l)${RESET}" {
    tmp_file=$(mktemp)
    tmp_link="${tmp_file}.link"

    ln -s "${tmp_file}" "${tmp_link}"
    expected="0"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_link}" \
        -x "${expected}"

    rm "${tmp_file}" "${tmp_link}"
}

@test "${MAGENTA}[TEST] test_file returns false for symlink pointing to directory (l)${RESET}" {
    tmp_dir=$(mktemp -d)
    tmp_link="${tmp_dir}.link"

    ln -s "${tmp_dir}" "${tmp_link}"
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_link}" \
        -x "${expected}"

    rmdir "${tmp_dir}"
    rm "${tmp_link}"
}

@test "${MAGENTA}[TEST] test_file returns false for broken symlink (l)${RESET}" {
    # Get unique name but dosen't create file.
    tmp_link=$(mktemp -u)
    tmp_target="${tmp_link}.nonexistent"

    # Create symlink pointing to non-existent target.
    ln -s "${tmp_target}" "${tmp_link}"
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_link}" \
        -x "${expected}"

    rm "${tmp_link}"
}

@test "${MAGENTA}[TEST] test_file returns false for named pipe (FIFO)${RESET}" {
    # Get unique name but dosen't create file.
    tmp_fifo=$(mktemp -u)

    # Create named pipe.
    mkfifo "${tmp_fifo}"
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_fifo}" \
        -x "${expected}"

    rm "${tmp_fifo}"
}

@test "${MAGENTA}[TEST] test_file returns false for character device (c)${RESET}" {
    # /dev/null is a character device that should exist on all Unix-like systems.
    target="/dev/null"
    expected="1"

    # Only run if /dev/null exists.
    if [ -c "${target}" ]; then
        assert_builder \
            -m "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "Character device /dev/null not available"
    fi
}

@test "${MAGENTA}[TEST] test_file returns false for block device (b)${RESET}" {
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
    for device in "${block_locations[@]}"; do
        if [ -b "${device}" ]; then
            target="${device}"
            break
        fi
    done

    if [ -n "${target}" ]; then
        assert_builder \
            -m "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "No accessible block device found for testing"
    fi
}

@test "${MAGENTA}[TEST] test_file returns false for Unix domain socket (s)${RESET}" {
    # Reason: This is a BATS test, access to bash is guarenteed.
    # shellcheck disable=SC3030
    uds_locations=(
        "/var/run/docker.sock"               # Docker daemon API socket - modern containerization
        "/run/docker.sock"                   # Alternative Docker location on newer systemd systems
        "/var/run/dbus/system_bus_socket"    # D-Bus system message bus - inter-process communication
        "/run/dbus/system_bus_socket"        # Alternative D-Bus location on systemd systems
        "/var/run/mysqld/mysqld.sock"        # MySQL database local connection socket
        "/var/run/postgresql/.s.PGSQL.5432"  # PostgreSQL database socket (port 5432)
        "/run/systemd/private"               # Systemd init system internal communication
        "/var/run/systemd/private"           # Legacy systemd socket location
        "/tmp/.X11-unix/X0"                  # X Window System display :0 communication socket
        "/var/run/acpid.socket"              # ACPI daemon for power management events
        "/run/udev/control"                  # udev device manager control socket
    )

    # Try to find an existing Unix domain socket in common locations
    target=""

    # Common system socket locations.
    for socket_path in "${uds_locations[@]}"; do
        # Check if it exists and is a socket using test -S
        if [ -S "${socket_path}" ]; then
            target="${socket_path}"
            break
        fi
    done

    if [ -n "${target}" ]; then
        expected="1"  # test -f should return false for sockets
        assert_builder \
            -m "${script}" \
            -h "${harness}" \
            -i "${target}" \
            -x "${expected}"
    else
        skip "No accessible Unix domain socket found in common system locations"
    fi
}

@test "${MAGENTA}[TEST] test_file returns false for non-existent file${RESET}" {
    # Use a path that's very unlikely to exist.
    target="/this/path/should/not/exist/$(date +%s%N)"
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${target}" \
        -x "${expected}"
}

@test "${MAGENTA}[TEST] test_file returns false for empty string${RESET}" {
    target="\n"
    expected="1"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${target}" \
        -x "${expected}"
}

@test "${MAGENTA}[TEST] test_file handles file with no read permissions (-)${RESET}" {
    tmp_file=$(mktemp)
    chmod 000 "${tmp_file}"  # Remove all permissions
    expected="0"  # Should still be detected as a file, even if unreadable

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    chmod 644 "${tmp_file}"
    rm "${tmp_file}"
}

@test "${MAGENTA}[TEST] test_file handles path with spaces (-)${RESET}" {
    tmp_file=$(mktemp --suffix=" with spaces")
    expected="0"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm "${tmp_file}"
}

@test "${MAGENTA}[TEST] test_file handles path with special characters (-)${RESET}" {
    # Create file with special characters (be careful with shell metacharacters)
    tmp_dir=$(mktemp -d)
    tmp_file="${tmp_dir}/file-with_special.chars@123"
    touch "${tmp_file}"
    expected="0"

    assert_builder \
        -m "${script}" \
        -h "${harness}" \
        -i "${tmp_file}" \
        -x "${expected}"

    rm -rf "${tmp_dir}"
}

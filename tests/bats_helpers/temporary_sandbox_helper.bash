#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/******************************************************************************
# [DESCRIPTION]
# BATS helper for setting up a mount namespace and chrooting inside of it. This
# version of the sandbox helper will only live long enough after the inital call 
# to get_isolated_fs_env in order to execute any passed commands through a pipe.
# There is a persistant sandbox helper as well that exists after the initial 
# system call and then requires an active release. Use cases may vary.
#
# *NOTE* Both versions were developed due to WSL2 being silly and forcing sudo
# for the nsenter command. Which is not native Linux behavior.
#
# [FILE] filesystem_setup_helper.bash
# [LICENSE] GNU GPLv3
# *****************************************************************************/

declare -g NS_PID
declare -g NS_FIFO

get_isolated_fs_env() {
    # Create a mount/user namespace
    unshare -U -r -m bash -c '
        NS_ROOT="/tmp/spfmt.jail-$$"
        WORKSPACE="${NS_ROOT}/spfmt.env"
        mkdir -p "${NS_ROOT}/tmp" # Premptively make tmp needed for the base of MOSI/MISO
        mkdir -p "${WORKSPACE}"

        # SPI naming scheme for symmetry from both sides
        # MOSI - Master out/Slave in
        # MISO - Master in/Slave out
        MISO="/tmp/miso"
        MOSI="/tmp/mosi"
        mkfifo "${NS_ROOT}${MISO}"
        mkfifo "${NS_ROOT}${MOSI}"

        # Symlinked on WSL2, resolve realpaths
        real_bin="$(realpath "/bin")"
        real_lib="$(realpath "/lib")"
        real_lib64="$(realpath "/lib64")"

        mkdir -p "${NS_ROOT}/usr"
        mkdir -p "${NS_ROOT}/usr/bin"
        mkdir -p "${NS_ROOT}/bin/lib"
        mkdir -p "$NS_ROOT"/lib/x86_64-linux-gnu
        mkdir -p "$NS_ROOT"/x86_64-linux-gnu

        # New mounts propogate in NEITHER direction!
        mount --make-rprivate /

        # Mounting bin actually works on WSL2?
        mkdir -p "${NS_ROOT}/bin"
        #mount --bind "${real_bin}" "${NS_ROOT}/bin"

        # Mount project
        mkdir -p "${NS_ROOT}/spfmt"
        mount --bind "$(realpath "$(pwd)")" "${NS_ROOT}/spfmt"

        # Dynamically collect needed libraries using ldd to find req shared objs
        for binary in /bin/bash /bin/bats /bin/sleep /bin/ls /bin/cat /usr/bin/awk /bin/cp; do
            if [ -f "${binary}" ]; then
                libs=$(ldd "${binary}" 2>/dev/null | grep -o "/lib[^ ]*")
                for lib in $libs; do
                    if [ -f "$lib" ]; then
                        # prepare path
                        lib_dirname=$(dirname "$lib")
                        mkdir -p "$NS_ROOT$lib_dirname"
                        # move bin over
                        cp "$lib" "$NS_ROOT$lib" 2>/dev/null || true
                    fi
                done
            fi
        done

        mkdir -p "${WORKSPACE}"
        mount -t tmpfs tmpfs "${WORKSPACE}"

        chroot "${NS_ROOT}" bash -c "
            exec 2>/tmp/chroot-error.log
            cd /spfmt.env

            while IFS= read -r cmd; do
                echo \"Got command: \$cmd\" >&2
                if [ \"\${cmd}\" = \"TERM\" ]; then
                    break
                fi

                eval \"\${cmd}\" > \"\${MISO}\" 2>&1
            done < \"\${MOSI}\"
        " &
        exec sleep infinity
    ' >/dev/null 2>&1 &

    NS_PID="$!"
    MOSI="/tmp/spfmt.jail-$NS_PID/tmp/mosi"
    MISO="/tmp/spfmt.jail-$NS_PID/tmp/miso"

    export NS_PID MISO MOSI
}

ns_exec() {
    if ! ps -p "${NS_PID}" >/dev/null 2>&1; then
        echo "[ERROR] Namespace does not exist yet/was cleaned up" >&2 
        return 1
    fi

     printf '%s\n' "$*" > "${MOSI}"

    cat "${MISO}"
}

kill_env() {
    if [ -n "$NS_PID" ]; then
        kill "$NS_PID" 2>/dev/null || true
    fi
}

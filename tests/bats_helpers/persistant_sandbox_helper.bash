#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/******************************************************************************
# [DESCRIPTION]
# BATS helper for setting up a mount namespace and chrooting inside of it. This
# version of the sandbox helper will persist after the inital call to
# get_isolated_fs_env and needs (should?) to be destroyed with kill env to free
# up system resources. There is a temporary sandbox helper as well that only
# exists at the initial system call and then releases its self. Use cases may
# vary.
#
# -NOTE- Both versions were developed due to WSL2 being silly and forcing sudo
# for the nsenter command. Which is not native Linux behavior.
#
# [FILE] filesystem_setup_helper.bash
# [LICENSE] GNU GPLv3
# *****************************************************************************/

declare -g NS_PID
declare -g NS_FIFO

get_isolated_fs_env() {
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    project_root="$(cd "$script_dir/../.." && pwd)"

    # FIFO to make sure namespace is ready before accessing
    NS_FIFO="/tmp/ns_fifo.$$"
    mkfifo "${NS_FIFO}"

    # Create a mount/user namespace
    unshare -U -r -m bash -c '
        NS_ROOT="/tmp/spfmt.jail-$$"
        WORKSPACE="${NS_ROOT}/spfmt.env"

        # Symlinked on WSL2, resolve realpaths
        real_bin="$(realpath "/bin")"
        real_lib="$(realpath "/lib")"
        real_lib64="$(realpath "/lib64")"

        mkdir -p "${NS_ROOT}/usr/bin"
        mkdir -p "${NS_ROOT}/bin/lib"
        mkdir -p "{$NS_ROOT}"/lib/x86_64-linux-gnu
        mkdir -p "${NS_ROOT}"/x86_64-linux-gnu
        mkdir -p "${WORKSPACE}"

        # New mounts propogate in NEITHER direction!
        mount --make-rprivate /

        # Mounting bin actually works on WSL2?
        mkdir -p "${NS_ROOT}/bin"
        mount --bind "${real_bin}" "${NS_ROOT}/bin"

        mkdir -p ${NS_ROOT}/spfmt
        mount --bind "'"$project_root"'" "${NS_ROOT}/spfmt"

        # Useful when debugging certain awk files that expect no stdin
        mkdir -p ${NS_ROOT}/dev
        touch "${NS_ROOT}/dev/null"  # Create empty file first
        mount --bind /dev/null "${NS_ROOT}/dev/null"

        # Dynamically collect all libraries using ldd to find req shared objs
        all_libs=$(
            for binary in /bin/bash /bin/sleep /bin/mkdir /bin/ls /bin/cat /usr/bin/awk /bin/cp /bin/touch; do
                [ -f "$binary" ] && ldd "$binary" 2>/dev/null
            done | grep -o "/lib[^ ]*" | sort -u
        )

        for lib in $all_libs; do
            if [ -f "$lib" ]; then
                libdir=$(dirname "$lib")
                mkdir -p "$NS_ROOT$libdir"
                cp "$lib" "$NS_ROOT$lib" 2>/dev/null || true
            fi
        done

        # Some other known programs that will be needed in the sandbox
        cp /usr/bin/awk "$NS_ROOT/usr/bin/"

        echo "READY" > "'"$NS_FIFO"'"

        exec sleep infinity

    ' > /dev/null &

    NS_PID="$!"
    export NS_PID

    # WAIT before returning. Has caused issues.
    if read -t 10 ready < "${NS_FIFO}"; then
        rm -f "$NS_FIFO"
        echo "[INFO] Namespace ${NS_PID} is ready" >&2
    else
        rm -f "$NS_FIFO"
        kill "$NS_PID" 2>/dev/null
        echo "[ERROR] Namespace initialization timeout" >&2
        return 1
    fi
}

ns_exec() {
    if ! ps -p "${NS_PID}" >/dev/null 2>&1; then
        echo "[ERROR] Namespace does not exist/was cleaned up" >&2 
        return 1
    fi

    sudo nsenter --mount=/proc/${NS_PID}/ns/mnt bash -c "
        chroot /tmp/spfmt.jail-"${NS_PID}" bash -c 'cd /spfmt.env && $*'
    " < /dev/null
}

kill_env() {
    if [ -n "$NS_PID" ]; then
        kill "$NS_PID" 2>/dev/null || true
    fi
}

filesystem_setup() {
    before="$1"
    after="$2"
    #/**
    # Where the test target lives, should be an actual name.
    # Look at the test/harness for find_editorconfig for more examples.
    # */
    target="$3"
    base="${4:-"/tmp"}"

    # Build up the directories before where .editorconfig lives.
    input="${base}" # prepend base dir.
    for ((i = 0; i < "${before}"; i++)); do
        input="${input}/dummy"
    done

    #/**
    # Create folder that will house .editorconfig, NOTE that naming should matter!
    # Test harnesses (such as find_editorconfig_harness.awk) should have logic to
    # pass/fail bases on some hint in the file name.
    # */
    input="${input}/${target}"

    # Save off location early.
    location="${input}"

    # Build up the directories before where .editorconfig lives.
    for ((i = 0; i < "${after}"; i++)); do
        input="${input}/dummy"
    done

    ns_exec "mkdir -p '${input}'"

    # location - Expected/target location, caller needs to make the file here.
    # input - Full constructed path from the lowest directory.
    echo "${location}:${input}"
}

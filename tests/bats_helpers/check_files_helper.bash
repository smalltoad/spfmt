#!/usr/bin/env sh

# File: source_files_helper.sh
# Desc: BATS specific helper script for sourcing files.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

# Load colors for visualization of error messages.
load "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

# Tests if path exists on the file system.
path_exists() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %spath_exists expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -e "$1" ] || {
        printf "%s%s[ERROR]%s %s File system does not contain path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

# Tests if path exists and points to a file.
is_file() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %sis_file expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -f "$1" ] || {
        printf "%s%s[ERROR]%s %sFile does not exist at path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

# Tests if path exists and points to a directory.
is_dir() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %sis_dir expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -d "$1" ] || {
        printf "%s%s[ERROR]%s %sDirectory does not exist at path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

# Tests if path exists and is readable.
is_readable() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %sis_readable expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -r "$1" ] || {
        printf "%s%s[ERROR]%s %sFile does not have read permissions at path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

# Tests if path exists and is writeable.
is_writable() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %sis_writable expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -w "$1" ] || {
        printf "%s%s[ERROR]%s %sFile does not have write permissions at path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

# Tests if path exists and is executable.
is_executable() {
    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    if [ "$#" -ne 1 ]; then
        printf "%s%s[ERROR]%s %sis_executable expects exactly one argument.%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "${RED}" "${RESET}" >&3
        return 1
    fi

    # DIRECTIVE JUSTIFICATION: Greater POSIX compliance.
    # shellcheck disable=SC2292
    [ -x "$1" ] || {
        printf "%s%s[ERROR]%s %sFile does not have execute permissions at path <%s>%s\n" \
            "${BOLD}" "${RED}" "${RESET}" "$1" "${RED}" "${RESET}" >&3
        return 1
    }
}

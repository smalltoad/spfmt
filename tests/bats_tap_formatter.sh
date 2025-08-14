#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Simple BATS TAP formatter.
# File: bats_formatter.
# License: GNU GPLv3

# Choose colour codes only if stdout is a tty.
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    GREEN="$(tput setaf 2 2>/dev/null || printf '\033[32m')"
    RED="$(tput setaf 1 2>/dev/null || printf '\033[31m')"
    YELLOW="$(tput setaf 3 2>/dev/null || printf '\033[33m')"
    RESET="$(tput sgr0 2>/dev/null || printf '\033[0m')"
else
    GREEN=""
    RED=""
    YELLOW=""
    RESET=""
fi

# Counters for summary.
passed=0
failed=0
skipped=0
total=0

# Iteration variables.
buffer=""
suite=""        # Used after extraction of suite from full file path to add to buffer.
known_suites="" # Used to keep track of suites, prevents repetitive prints.

print_lines() {
    buffer="$1"
    if echo "${buffer}" | grep -iE "suite" >/dev/null; then
        # Does the test contain a fail?
        suite_failed=$(echo "${buffer}" | grep -E "not ok" 2>/dev/null)
        echo "${buffer}" | while IFS= read -r line; do
            case "${line}" in
                SUITE\ *)
                    if [ ! -z "${suite_failed}" ]; then
                        printf '%s%s%s\n' "${RED}" "${line}" "${RESET}"
                    else
                        printf '%s%s%s\n' "${GREEN}" "${line}" "${RESET}"
                    fi
                    ;;
                ok\ *)
                    printf '%s%s%s\n' "${GREEN}" "${line}" "${RESET}"
                    ;;
                not\ ok\ *)
                    printf '%s%s%s\n' "${RED}" "${line}" "${RESET}"
                    ;;
                \#\ SKIP* | \#\ skip*)
                    printf '%s%s%s\n' "${YELLOW}" "${line}" "${RESET}"
                    ;;
                *) ;;
            esac
        done

        # Clear buffer now that it is printed.
        buffer=""
    fi
}

collect_lines() {
    # Read TAP from stdin line-by-line.
    while IFS= read -r line; do
        case "${line}" in
            # TAP Test range. Always print.
            1..*)
                printf '%s\n' "${line}"
                ;;
            # New suite of tests belonging to a module under /src folder.
            suite\ *)
                # Remove the tests sub sir and everything before it.
                suite="${line#*tests/}"
                # Remove everything after the first forward slash.
                suite="${suite%%/*}"

                # Have we already added this suite print out to the buffer?
                if ! echo "${known_suites}" | grep -E "${suite}" >/dev/null; then
                    # if not, print the buffer and clear it.
                    print_lines "${buffer}"

                    # Now that the buffer has been printed and cleared, restart.
                    buffer="SUITE ${suite} module"
                    # Register in known suites
                    known_suites="${known_suites} ${suite}"
                fi
                ;;
            # Test that has passed.
            ok\ *)
                passed=$((passed + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                #printf '%s%s%s\n' "${GREEN}" "${line}" "${RESET}"
                ;;
            # Test that has failed.
            not\ ok\ *)
                failed=$((failed + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                #printf '%s%s%s\n' "${RED}" "${line}" "${RESET}"
                ;;
            # Skipped test.
            \#\ SKIP* | \#\ skip*)
                skipped=$((skipped + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                #printf '%s%s%s\n' "${YELLOW}" "${line}" "${RESET}"
                ;;
            # Something else?
            *)
                #printf '%s\n' "${line}"
                ;;
        esac
    done

    # Print the contents of the buffer, it still has one suite.
    print_lines "${buffer}"
}

print_summary() {
    printf '\nSummary: %d total, %s%d passed%s, %s%d failed%s, %s%d skipped%s\n' \
        "${total}" \
        "${GREEN}" "${passed}" "${RESET}" \
        "${RED}" "${failed}" "${RESET}" \
        "${YELLOW}" "${skipped}" "${RESET}"
}

main() {
    collect_lines
    print_summary
}

main "$@"

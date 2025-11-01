#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description:
# Simple BATS TAP formatter. Uses color to convey pass/fail in tty.
#
# File: bats_formatter.
# License: GNU GPLv3

# Choose color codes only if stdout is a tty.
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

TREE_BRANCH="$(printf '\342\224\234\342\224\200\342\224\200')" # ├──
TREE_END="$(printf '\342\224\224\342\224\200\342\224\200')"    # └──
TREE_HOR="$(printf '\342\224\200\342\224\200')"                # ───
TREE_VERT="$(printf '\342\224\202')"                           # │

# Counters for summary.
passed=0
failed=0
skipped=0
total=0

# Iteration variables.
buffer=""
suite=""        # Used after extraction of suite from full file path to add to buffer.
known_suites="" # Used to keep track of suites, prevents repetitive prints.

#/**
# * Prints a single complete buffer at a time. Looks ahead to color the headers
# * of suites and test file starting blocks.
# */
print_lines() {
    # Buffer passed in.
    buffer="$1"
    # Stores infos for when the actual test case appears.
    info_buffer=""

    if echo "${buffer}" | grep -iE "suite" >/dev/null; then
        # Does the test contain a fail?
        module_failed=$(echo "${buffer}" | grep -E "not ok" 2>/dev/null)

        module_count=$(echo "${buffer}" | grep -o MODULE | wc -l)
        suite_count=$(echo "${buffer}" | grep -o SUITE | wc -l)
        test_count=$(echo "${buffer}" | grep -cE "^(ok|not ok)")

        # Start at one to avoid +1 everywhere when comparing.
        module_curr=0
        suite_curr=0
        test_curr=0

        color_col_1=""
        color_col_2=""
        color_col_3=""
        draw_col_1=""
        draw_col_2=""
        draw_col_3=""

        printf '%b\n' "${buffer}" | while IFS= read -r line; do
            case "${line}" in
                SPFMT\ *)
                    printf "\n%s\n" "${line}"
                    ;;
                MODULE\ *)
                    # Look ahead and see if the enitre module has a fail or not.
                    if [ ! -z "${module_failed}" ]; then
                        color_col_1="${RED}"
                    else
                        color_col_1="${GREEN}"
                    fi

                    if [ "${module_count}" -eq "1" ] || [ "${module_curr}" -ne "${module_count}" ]; then
                        draw_col_1="${TREE_END}"
                    else
                        draw_col_1="${TREE_BRANCH}"
                    fi

                    module_curr=$((module_curr + 1))
                    printf '%s%s%s%s\n' "${color_col_1}" "${draw_col_1}" "${line}" "${RESET}"
                    ;;
                SUITE\ *)
                    suite_curr=$((suite_curr + 1))

                    # Grab suite text using embedded AWK script.
                    suite_text=$(extract_suite_from_buffer "${buffer}" "${line##SUITE }")
                    # Determine number of passes, fails and get the total test count.
                    fails=$(echo "${suite_text}" | grep -cE "^not ok " 2>/dev/null)
                    passes=$(echo "${suite_text}" | grep -cE "^ok " 2>/dev/null)
                    total=$((passes + fails))

                    # Look ahead and see if suite has a fail or not.
                    if [ "${fails}" -ne 0 ]; then
                        color_col_2="${RED}"
                    else
                        color_col_2="${GREEN}"
                    fi

                    # More suites? Print a branch, otherwise a stub.
                    if [ "${suite_curr}" -ne "${suite_count}" ]; then
                        draw_col_2="${TREE_BRANCH}"
                    else
                        draw_col_2="${TREE_END}"
                    fi

                    # Safe to check directly against col1 because it never gets called twice per function call.
                    if [ "${draw_col_1}" = "${TREE_BRANCH}" ]; then
                        printf '%s%s%s  %s%s%s [%s/%s]%s\n' "${color_col_1}" "${TREE_VERT}" "${RESET}" "${color_col_2}" "${draw_col_2}" "${line}" "${passes}" "${total}" "${RESET}"
                    else
                        printf '   %s%s%s [%s/%s]%s\n' "${color_col_2}" "${draw_col_2}" "${line}" "${passes}" "${total}" "${RESET}"
                    fi

                    #printf '%s%s  %s%s [%s/%s]%s\n' "${color}" "${TREE_VERT}" "${TREE_BRANCH}" "${line}" "${passes}" "${total}" "${RESET}"
                    ;;
                ok\ *)
                    test_curr=$((test_curr + 1))

                    # More tests? Print a branch, otherwise a stub.
                    if [ "${test_curr}" -ne "${total}" ]; then
                        draw_col_3="${TREE_BRANCH}"
                    else
                        draw_col_3="${TREE_END}"
                        test_curr=0
                    fi

                    # Last suite already printed? No need for column 2 then.
                    if [ "${suite_curr}" -eq "${suite_count}" ]; then
                        printf '      %s%s%s%s\n' "${GREEN}" "${draw_col_3}" "${line}" "${RESET}"
                    else
                        printf '   %s%s%s  %s%s%s%s\n' "${GREEN}" "${TREE_VERT}" "${RESET}" "${GREEN}" "${draw_col_3}" "${line}" "${RESET}"
                    fi

                    info_buffer=""
                    ;;
                not\ ok\ *)
                    # Print failing test case.
                    printf '%s%s\t\t%s%s\n' "${RED}" "${TREE_VERT}" "${line}" "${RESET}"

                    # Because of literal backslashes mix with newlines, must first
                    # print with %b then add format related newlines and tabs.
                    printf '%b\n' "${info_buffer}" | while IFS= read -r info_line; do
                        if [ -n "${info_line}" ]; then # Skip empty lines.
                            printf '\t\t\t%s%s%s\n' "${RED}" "${info_line}" "${RESET}"
                        fi
                    done

                    # Reset info buffer.
                    info_buffer=""
                    ;;
                \[INFO\]\ *)
                    info_buffer="${info_buffer}"'\n'"${line}"
                    ;;
                \#\ SKIP* | \#\ skip*)
                    printf '\t\t%s%s%s\n' "${YELLOW}" "${line}" "${RESET}"
                    ;;
                *) ;;
            esac
        done

        # Clear buffer now that it is printed.
        buffer=""
    fi
}

#/**
# * Collect all lines as the tests finish. This is required to add colloring to
# * test cases based off fail/pass status. By collecting all the lines first
# * modules and suite headers can now also be determined to be pass/fail by
# * looking ahead in the buffer.
# */
collect_lines() {
    # Read TAP from stdin line-by-line.
    while IFS= read -r line; do
        case "${line}" in
            # SPFMT header and TAP Test range. Always print.
            1..*)
                tests="${line#*..}"
                buffer="SPFMT FUNCTION TEST SUITE | TOTAL TESTS: ${tests}"
                ;;
            # New suite of tests belonging to a module under /src folder.
            suite\ *)
                # Remove the (tests/)modules sub dir and everything before it.
                suite="${line#*modules/}"
                # Remove everything after the first forward slash.
                suite="${suite%%/*}"

                # Have we already added this suite print out to the buffer?
                if ! echo "${known_suites}" | grep -E "${suite}" >/dev/null; then
                    # if not, print the buffer and clear it.
                    print_lines "${buffer}"

                    # Now that the buffer has been printed and cleared, restart.
                    buffer="${buffer}\nMODULE src/${suite}"
                    # Register in known suites, next time this case is hit the
                    # buffer will get printed.
                    known_suites="${known_suites} ${suite}"
                fi
                ;;
            \[START\]\ *)
                file="${line##* }"
                buffer="${buffer}"'\n'"SUITE ${file}"
                ;;
            # Test that has passed.
            ok\ *)
                passed=$((passed + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                ;;
            # Test that has failed.
            not\ ok\ *)
                failed=$((failed + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                ;;
            # Skipped test.
            \#\ SKIP* | \#\ skip*)
                skipped=$((skipped + 1))
                total=$((total + 1))
                buffer="${buffer}"'\n'"${line}"
                ;;
            \[INFO\]\ *)
                buffer="${buffer}"'\n'"${line}"
                ;;
            # Something else? do nothing.
            *)
                buffer="${buffer}"'\n'"${line}"
                ;;
        esac
    done

    # Print the contents of the buffer, it still has one suite.
    print_lines "${buffer}"
}

# Embedded AWK script that extracts only the passed suite from a buffer.
extract_suite_from_buffer() {
    buffer="$1"
    target="$2"

    printf '%b\n' "${buffer}" | awk -v suite="${target}" '
    # Start printing when the target suite appears.
    $1 == "SUITE" && $2 == suite {
      inside = 1
      print
      next
    }

    # if printing and another SUITE or MODULE header appears, stop printing.
    inside && ($1 == "SUITE" || $1 == "MODULE") { exit }

    # while inside the suite, print lines
    inside == 1 { print }
  '
}

# Prints out the summary of the tests.
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

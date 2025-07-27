#!/usr/bin/env bash

# File: color_helper.bash
# Desc: BATS helper to provide colors.
# Author: Joseph Mowery <mowery.joseph@outlook.com>

# Generate ANSI escape sequences dynamically using Portable Terminal Control (tput)
# REASON FOR SHELLCHECK DIRECTIVE: Greater POSIX compliance.
# shellcheck disable=SC2292

if [ -n "${BATS_TEST_FILENAME}" ] || [ -n "${BATS_TEST_NAME}" ] || [ -t 3 ] || [ -t 1 ]; then
    BLACK=$(tput setaf 0 2>/dev/null)
    RED=$(tput setaf 1 2>/dev/null)
    GREEN=$(tput setaf 2 2>/dev/null)
    YELLOW=$(tput setaf 3 2>/dev/null)
    BLUE=$(tput setaf 4 2>/dev/null)
    MAGENTA=$(tput setaf 5 2>/dev/null) # Sometimes called purple
    CYAN=$(tput setaf 6 2>/dev/null)    # Light blue/teal
    WHITE=$(tput setaf 7 2>/dev/null)

    # Text styling options
    BOLD=$(tput bold 2>/dev/null)
    DIM=$(tput dim 2>/dev/null)
    UNDERLINE=$(tput smul 2>/dev/null)

    # Reset code
    RESET=$(tput sgr0 2>/dev/null)
else
    # Fallback, no colors if this is output is being redirected
    # REASON FOR SHELLCHECK DIRECTIVE: Required for safe fallback.
    # shellcheck disable=SC2034
    BLACK=""
    # shellcheck disable=SC2034
    RED=""
    # shellcheck disable=SC2034
    GREEN=""
    # shellcheck disable=SC2034
    YELLOW=""
    # shellcheck disable=SC2034
    MAGENTA=""
    # shellcheck disable=SC2034
    CYAN=""
    # shellcheck disable=SC2034
    WHITE=""
    # shellcheck disable=SC2034
    BLUE=""
    # shellcheck disable=SC2034
    BOLD=""
    # shellcheck disable=SC2034
    DIM=""
    # shellcheck disable=SC2034
    UNDERLINE=""
    # shellcheck disable=SC2034
    RESET=""
fi

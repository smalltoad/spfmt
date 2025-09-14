#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: CLI wrapper for spfmt, provides a similar UX when using the help flag.
# File: cli_wrapper.sh
# License: GNU GPLv3

SPFMT_AWK_PROGRAM=$(
    cat <<'EOF'
AWK_CODE_PLACEHOLDER
EOF
)

case "$@" in
    # If help was requested, format the correct awk command for help.
    -h | --help)
        printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - /dev/null -h
        ;;
    # Otherwise, run the program.
    *)
        printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - /dev/null "$@"
        ;;
esac

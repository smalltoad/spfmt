#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: CLI wrapper for spfmt, provides CLI specific handling while
#     obfuscating AWK cli options away from the user.
# File: cli_wrapper.sh
# License: GNU GPLv3

#===============#
# SPFMT PROGRAM #
#===============#

# Embedded AWK program, placeholder gets substituted on build through makefile.
SPFMT_AWK_PROGRAM=$(
    cat <<'EOF'
AWK_CODE_PLACEHOLDER
EOF
)

#===============#
# TRAP HANDLERS #
#===============#

traps=""

#/**
# * Multiple traps may be needed depending on control flow.
# * add_trap handles keeping track of all traps to preform a full clean-up.
# */
add_trap() {
    if [ -n "${traps}" ]; then
        traps="${traps}; $1"
    else
        traps="${traps}"
    fi
}

preform_traps() {
    if [ -n "${traps}" ]; then
        eval "${traps}"
    fi
}

# This trap will always preform all clean up functions passed to add_trap!
trap 'preform_traps' EXIT INT TERM

#=====================#
# SPFMT TMP DIRECTORY #
#=====================#

# In the event mktemp is not on system.
TMP_DIR_FALLBACK="/var/tmp/spfmt"
TMP_DIR=""

# Temporary directory to store files while preforming atomic operations.
create_tmp_directory() {
    # Try mktemp first, else fall back to PID-based approach.
    if command -v mktemp >/dev/null 2>&1; then
        TMP_DIR=$(mktemp -d -t "spfmt.$$.XXXXXX") || {
            # If mktemp does not succeed, resort to UNSAFE fallback of using /var/tmp...
            printf "[WARNING] System did not have mktemp bin for tmp directory creation!\n"
            printf "[WARNING] Consider installing mktemp for a safer tmp directory.\n"
            mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null
        }
    else
        # If mktemp does not exist, resort to fallback.
        TMP_DIR=$(mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null)
    fi

    add_trap "rm -rf '${TMP_DIR}'"
}

#============#
# CLI PARSER #
#============#

awk_files=""
awk_vars=""

# Handle flags/options.
while [ $# -gt 0 ]; do
    case "$1" in
        # If help was requested, format the correct awk command for help.
        -h | --help)
            printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - -v show_help=1
            exit "$?"
            ;;
        # If version was requested, format the correct awk command for version.
        -v | --version)
            printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - -v show_version=1
            exit "$?"
            ;;
        -d | --debug)
            awk_vars="${awk_vars} -v DEBUG_MODE=1"
            shift 1
            ;;
        -dd | --dev-mode)
            awk_vars="${awk_vars} -v DEBUG_MODE=1 -v DEV_MODE=1"
            shift 1
            ;;
        -i | --in-place)
            awk_vars="${awk_vars} -v in_place=0"
            shift 1
            ;;
        -c | --indent-char)
            if [ $# -lt 2 ] || [ "$(printf '%s' "$2" | cut -c1)" = "-" ]; then
                printf "Option -c|--indent-char requires an argument.\n"
                exit 2
            fi
            # Validate indentation type.
            case "$2" in
                # Only space and tab is supported.
                space)
                    awk_vars="${awk_vars} -v indent_char=space"
                    ;;
                tab)
                    awk_vars="${awk_vars} -v indent_char=tab"
                    ;;
                *)
                    printf "Invalid indent type '%s'. Only 'space' or 'tab' options are supported.\n" "$2"
                    exit 2
                    ;;
            esac
            shift 2
            ;;
        -s | --indent-size)
            if [ $# -lt 2 ] || [ "$(printf '%s' "$2" | cut -c1)" = "-" ]; then
                printf "Option  -s|--indent-size requires an argument.\n"
                exit 2
            fi
            # Validate that size is a positive number.
            case "$2" in
                '' | *[!0-9]*)
                    printf "Indent size must be a positive number, got '%s'.\n" "$2"
                    exit 2
                    ;;
                *)
                    if [ "$2" -lt 1 ]; then
                        printf "Width must be greater than 0, got '%s'.\n" "$2"
                        exit 2
                    fi
                    awk_vars="${awk_vars} -v indent_size=$2"
                    ;;
            esac
            shift 2
            ;;
        -*)
            printf "[ERROR] Option %s not recognized.\n" "$1"
            exit 2
            ;;
        # Assume file, assure it is regular and readable.
        *)
            if [ ! -f "$1" ]; then
                printf "[ERROR] Not a file: %s\n" "$1"
                exit 2
            fi
            if [ ! -r "$1" ]; then
                printf "[ERROR] File not readable: %s\n" "$1"
                exit 2
            fi

            awk_files="${awk_files} $1"
            shift 1
            ;;
    esac
done

# Immediate bail if both stdin and files were provided.
if [ -n "${awk_files}" ] && [ ! -t 0 ]; then
    echo "[ERROR] spfmt doesn't handle stdin and file inputs simultaneously."
    exit 1
fi

# Prepare tmp directory, assume at this point spfmt will be invoked.
create_tmp_directory

#/**
# * Handle stdin if process is in a terminal AND no files were passed.
# *
# * Because stdin is usually the spfmt awk progam, in order to make room for
# * the users stdin arguments spfmt will be written to a tmp file and then
# * passed as a file arg through awk.
# */
if [ -z "${awk_files}" ] && [ ! -t 0 ]; then
    awk_temp_file=$(mktemp) || {
        printf "[ERROR] Failed to create temporary file with mktemp.\n" >&2
        exit 1
    }

    # Ensure cleanup of tmp file on exit.
    add_trap "rm -f '${awk_temp_file}'"

    # Write the AWK program to the temporary file.
    printf '%s\n' "${SPFMT_AWK_PROGRAM}" >"${awk_temp_file}"

    awk -f "${awk_temp_file}" -v OUTPUT_PATH="${TMP_DIR}"${awk_vars}

# Otherwise handle files normally using embedded AWK program.
else
    concat_command="awk -f - ${awk_vars}${awk_files}"

    # TODO: Remove this line, was used during testing.
    echo "${concat_command}"

    # Intentionally NOT QUOTED, quotes will make awk believe these are all file names/include spaces.
    printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - -v OUTPUT_PATH="${TMP_DIR}"${awk_vars}${awk_files}
fi

# Exit with spfmts exit code.
exit $?

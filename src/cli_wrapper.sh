#!/usr/bin/env sh
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# * DESCRIPTION:
# * CLI wrapper for spfmt, provides CLI specific handling while obfuscating AWK
# * cli options away from the user.
# *
# * FILE: cli_wrapper.sh
# * LICESNE: GNU GPLv3
# */

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
        traps="$1"
    fi
}

# Disabled because shellcheck does not see function called below in '' for trap.
# shellcheck disable=SC2329
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

# Temporary working dir to store files while preforming atomic operations.
create_working_directory() {
    # Try mktemp first, else fall back to PID-based approach.
    if command -v mktemp >/dev/null 2>&1; then
        TMP_DIR=$(mktemp -d -t "spfmt.$$.XXXXXX") || {
            # If mktemp does not succeed, resort to UNSAFE fallback of using /var/tmp...
            printf "[WARNING] Consider installing mktemp for a safer tmp directory.\n"
            mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null
        }
    else
        # If mktemp does not exist, resort to fallback.
        TMP_DIR=$(mkdir -p "${TMP_DIR_FALLBACK}.$$" 2>/dev/null)
    fi

    add_trap "rm -rf '${TMP_DIR}'"
}

main() {

    #============#
    # CLI PARSER #
    #============#

    # Debug level maps to the verbosity modes:
    # - debug mode(1)
    # - dev mode (2)
    DEBUG_LEVEL=0
    DEBUG_MODE=0
    DEV_MODE=0
    # Stores passed files, files don't need a flag.
    awk_files=""
    awk_vars=""

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
            -d*)
                # Get the consecuative d's
                debugs="${1#-}"

                # Deconstruct debug verbosity and find debug level.
                while [ -n "${debugs}" ]; do
                    to_remove="${debugs#?}"
                    next_char="${debugs%"${to_remove}"}"

                    if [ "${next_char}" = "d" ]; then
                        DEBUG_LEVEL=$((DEBUG_LEVEL + 1))
                    else
                        printf "[ERROR] Debug level is set using 'd' only.\n"
                        exit 2
                    fi

                    debugs="${to_remove}"
                done

                if [ "${DEBUG_LEVEL}" -gt 0 ] && [ "${DEBUG_MODE}" -eq 0 ]; then
                    echo "debug mode !"
                    DEBUG_MODE=1
                    awk_vars="${awk_vars}-v DEBUG_MODE=1 "
                fi

                if [ "${DEBUG_LEVEL}" -gt 1 ] && [ "${DEV_MODE}" -eq 0 ]; then
                    echo "dev mode !"
                    DEV_MODE=1
                    awk_vars="${awk_vars}-v DEV_MODE=1 "
                fi

                shift 1
                ;;
            --debug)
                if [ "${DEBUG_MODE}" -eq 0 ]; then
                    DEBUG_MODE=1
                    awk_vars="${awk_vars}-v DEBUG_MODE=1 "
                fi
                shift 1
                ;;
            --dev-mode)
                if [ "${DEV_MODE}" -eq 0 ]; then
                    DEV_MODE=1
                    awk_vars="${awk_vars}-v DEV_MODE=1 "
                fi
                shift 1
                ;;
            -i | --in-place)
                awk_vars="${awk_vars}-v in_place=0 "
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
                        awk_vars="${awk_vars}-v indent_char=space "
                        ;;
                    tab)
                        awk_vars="${awk_vars}-v indent_char=tab "
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
            # Assume file, assure it is regular and readable. Otherwise bail.
            *)
                if [ ! -f "$1" ]; then
                    printf "[ERROR] Not a file: %s\n" "$1"
                    exit 2
                fi
                if [ ! -r "$1" ]; then
                    printf "[ERROR] File not readable: %s\n" "$1"
                    exit 2
                fi

                awk_files="${awk_files} $1 "
                shift 1
                ;;
        esac
    done

    # Immediate bail if both stdin and files were provided.
    if [ -n "${awk_files}" ] && [ ! -t 0 ]; then
        echo "[ERROR] spfmt doesn't handle stdin and file inputs simultaneously."
        exit 1
    fi

    # Prepare tmp working directory.
    # Mus be created everytime, does not persist after spfmt executes.
    create_working_directory

    #============#
    # CALL SPFMT #
    #============#

    #/**
    # * First if statement handles stdin if in a terminal AND no files were passed.
    # *
    # * Because stdin is usually the spfmt awk progam, in order to make room for
    # * the users stdin arguments spfmt will be written to a tmp file and then
    # * passed as a file arg through to awk.
    # */
    if [ -z "${awk_files}" ] && [ ! -t 0 ]; then
        awk_temp_file=$(mktemp) || {
            printf "[ERROR] Failed to create temporary spfmt file with mktemp.\n" >&2
            exit 1
        }

        # Ensure cleanup of tmp file on exit.
        add_trap "rm -f '${awk_temp_file}'"

        # Write the AWK program to the temporary file.
        printf '%s\n' "${SPFMT_AWK_PROGRAM}" >"${awk_temp_file}"

        awk -v OUTPUT_PATH="${TMP_DIR}" ${awk_vars} -f "${awk_temp_file}"

    # Otherwise handle files normally using embedded AWK program.
    else
        echo "awk -v OUTPUT_PATH=${TMP_DIR} ${awk_vars} -f ${awk_temp_file}"

        # Intentionally NOT QUOTED, quotes will make awk believe these are all file names/not split spaces.
        printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -v OUTPUT_PATH="${TMP_DIR}" ${awk_vars} -f - ${awk_files}
    fi

    # Exit with spfmts exit code.
    exit $?
}

case "$(basename -- "$0")" in
    spfmt)
        main "$@"
        ;;
    *)
        #/**
        # * Do nothing...
        # *
        # * Allows both:
        # * 1. Script to be sourced WITHOUT execution.
        # * 2. For testing via shellcheck.
        # */
        ;;
esac

#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: POSIX-compliant AWK script to format ShellSpec test files.
# File: spfmt.awk
# License: GNU GPLv3

BEGIN {
    # ======================= #
    # VARIABLE INITIALIZATION #
    # ======================= #

    # Program metadata
    PROGRAM_NAME = "spfmt"
    VERSION = "0.1.0"

    # Default configuration variables, overriddable via .editorconfig or CLI.
    # NOTE: In editorconfig.awk these get modified directly based on name.
    indent_size = ""
    indent_char = ""

    # Current indentation level, used to track depth.
    current_level = 0

    # Flags/options spfmt handles.
    DEBUG_MODE = 0 # Debug mode flag, turns on verbose output.
    defaults_overriden = 0 # Flag to track if defaults were overridden.
    in_place = 0 # In-place flag, files will be modified directly with backups.
    show_help = 0
    show_version = 0

    # Files found in args during parsing.
    file_count = 0

    # ============================= #
    # PARSE AND CONFIGURATION SETUP #
    # ============================= #

    # Process command line arguments, if it was unsuccessful then bail.
    if (parse_arguments() != 0) {
        exit 2
    }

    # Immediately after parsing, check for debug mode first.
    if (DEBUG_MODE) {
        print "[DEBUG] Debug mode enabled."
    }

    # Handle help and version options first, then exit.
    if (show_help) {
        if (DEBUG_MODE) {
            print "[DEBUG] Help requested."

            if (defaults_overriden != 0 || file_count > 0) {
                print\
                    "[DEBUG] CLI options were provided, but help option takes preceedence and causes early exit."
            }
        }

        print_help()
    }
    else if (show_version) {
        if (DEBUG_MODE) {
            print "[DEBUG] Version requested."

            if (defaults_overriden != 0 || file_count > 0) {
                print\
                    "[DEBUG] CLI options were provided, but version option takes preceedence and causes early exit."
            }
        }

        print_version()
    }

    # If CLI parameters were passed for formatting, don't search for another source.
    if (defaults_overriden == 0) {
        if (DEBUG_MODE) {
            print "[DEBUG] No CLI formatting options found."
            print "[DEBUG] Searching for .editorconfig file."
        }

        load_config_file()

        # Resort to sane defaults if no overrides provided via CLI or .editorconfig file.
        if (defaults_overriden == 0) {
            if (DEBUG_MODE) {
                print "[DEBUG] No .editorconfig formatting options found."
            }

            indent_size = "4"
            indent_char = " "

            if (DEBUG_MODE) {
                print "[DEBUG] Resorting to sane defaults of space indentation and indent size of " + indent_size + "."
            }
        }
    }

    # Print final settings for formatting.
    if (DEBUG_MODE) {
        print "[DEBUG] Final formatting settings"
        print "[DEBUG] indent size: " indent_size
        print "[DEBUG] indent char: " indent_char
        # TODO: Add configuration for line ending.
        # print "[DEBUG] line-ending: "
    }

    # ============= #
    # PROCESS FILES #
    # ============= #

    # If no files specified, process stdin.
    if (file_count == 0) {
        if (DEBUG_MODE) {
            print "[DEBUG] No files found from CLI."
            print "[DEBUG] Processing from stdin instead..."
        }

        # TODO: Implement function.
        process_input()
    } else {
        # TODO: Implement function.
        process_files()
    }
}

# Parse command line arguments using ARGC/ARGV
function parse_arguments(    i, arg) {
    for (i = 1; i < ARGC; i++) {
        arg = ARGV[i]

        # Handle options in order of priority.
        if (arg == "-h" || arg == "--help") {
            show_help = 1
            ARGV[i] = ""
        }
        else if (arg == "-v" || arg == "--version") {
            show_version = 1
            ARGV[i] = ""
        }
        else if (arg == "-d" || arg == "--debug") {
            DEBUG_MODE = 1
            ARGV[i] = ""
        }
        else if (arg == "-i" || arg == "--in-place") {
            in_place = 1
            ARGV[i] = ""
        }
        else if (arg == "-s" || arg == "--indent-size") {
            # Is there another argument for indent size and is it an integer?
            if (i + 1 < ARGC && is_a_number(ARGV[i + 1]) == 0) {
                defaults_overriden = 1
                indent_size = ARGV[i + 1]
                ARGV[i] = ""
                ARGV[i + 1] = ""
                i++

                if (DEBUG_MODE) {
                    print "[DEBUG] indent size option provided with good argument of: " \
                        indent_size > "/dev/stderr"
                }
            } else {
                print "[ERROR] -s|--indent-size requires a positive integer."
                return 2
            }
        }
        else if (arg == "-c" || arg == "--indent-char") {
            # Is there another argument for indent char and is it supported?
            if (i + 1 < ARGC && is_an_indent(ARGV[i + 1]) == 0) {
                defaults_overriden = 1
                indent_char = ARGV[i + 1]
                ARGV[i] = ""
                ARGV[i + 1] = ""
                i++

                if (DEBUG_MODE) {
                    print "[DEBUG] indent char option provided with good argument of: " \
                        indent_char > "/dev/stderr"
                }
            } else {
                print "[ERROR] -c|--indent-char flag found with no positional argument."
                return 2
            }
        }
        else if (arg == "-f" || arg == "--file") {
            # Is there another argument passed in after?
            if(i + 1 < ARGC) {
                if (DEBUG_MODE) {
                    print "[DEBUG] Found a file: " ARGV[i + 1] > "/dev/stderr"
                }
                file_list[file_count] = ARGV[i + 1]
                file_count++
                ARGV[i] = ""
                ARGV[i + 1] = ""
                i++
            } else {
                print "[ERROR] -f|--file flag found with no positional argument."
                return 2
            }
        }
        else if (arg ~ /^-/) {
            printf("[ERROR] Unknown option: %s\n", arg)
            print "[ERROR] Use --help for usage information."
            return 2
        }
    }
}

# TODO: Update empty line handling to strip whitespace.
# Handles empty lines, preserve them as-is
/^[ \t]*$/ {
    print $0
    next
}

# Handle 'End' statements, decrease in indentation level now.
/^[ \t]*End[ \t]*$/ {
    current_level = (current_level > 0) ? current_level - 1 : 0

    if (DEBUG_MODE) {
        printf("[DEBUG] End found, level now %d\n", current_level)
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    next
}

# Handle scope-starting keywords, increase indentation level after printing.
/^[ \t]*(Describe|Context|It|Before|After|BeforeAll|AfterAll|BeforeEach|AfterEach)[ \t]/ {
    if (DEBUG_MODE) {
        printf(\
            "[DEBUG] Block keyword found: %s, level %d\n",
            $1,
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    current_level++
    next
}

# Handle statement keywords, maintain current indentation level.
/^[ \t]*(When|The|Skip|Pending|Todo)[ \t]/ {
    if (DEBUG_MODE) {
        printf(\
            "[DEBUG] Statement keyword found: %s, level %d\n",
            $1,
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    next
}

# Default case, handle all other lines such as comments.
{
    if (DEBUG_MODE) {
        printf(\
            "[DEBUG] Other line, maintaining level %d\n",
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
}

# Dynamically create indentation string for any given level.
function create_indent(    indent, i) {
    indent = ""

    for (i = 0; i < level * indent_size; i++) {
        indent = indent indent_char
    }

    return indent
}

function print_help() {
    printf("%s - Format ShellSpec test files\n\n", PROGRAM_NAME)
    printf("USAGE:\n")
    printf("    %s [OPTIONS] [FILE...]\n", PROGRAM_NAME)
    printf("    %s -h|--help\n", PROGRAM_NAME)
    printf("    %s --version\n\n", PROGRAM_NAME)

    printf("DESCRIPTION:\n")
    printf(\
        "    Formats ShellSpec test files with proper indentation and structure.\n"\
    )
    printf(\
        "    If no files are specified, reads from stdin and writes to stdout.\n\n"\
    )

    printf("OPTIONS:\n")
    printf(\
        "    -i, --in-place        Edit files in-place (creates .bak backup)\n"\
    )
    printf(\
        "    -s, --indent-size N   Set indentation size (default: %d)\n",
        indent_size\
    )
    printf(\
        "    -c, --indent-char C   Set indentation character (default: space)\n"\
    )
    printf("    -d, --debug           Enable debug output to stderr\n")
    printf("    -h, --help            Show this help message\n")
    printf("    --version             Show version information\n\n")

    printf("EXAMPLES:\n")
    printf(\
        "    %s test_spec.sh                    # Format to stdout\n",
        PROGRAM_NAME\
    )
    printf(\
        "    %s -i spec/*.sh                    # Format multiple files in-place\n",
        PROGRAM_NAME\
    )
    printf(\
        "    %s -s 2 spec/my_spec.sh            # Custom indentation\n",
        PROGRAM_NAME\
    )
    printf(\
        "    cat test_spec.sh | %s              # From stdin\n", PROGRAM_NAME\
    )

    exit 0
}

function print_version() {
    printf("%s v%s\n", PROGRAM_NAME, VERSION)
    exit 0
}

END {
    if (DEBUG_MODE) {
        printf(\
            "# Processing complete. Final level: %d\n",
            current_level > "/dev/stderr"\
        )
    }

    if (current_level != 0) {
        printf(\
            "# Warning: Unmatched blocks detected (level %d). Check your Describe/End pairs.\n",
            current_level > "/dev/stderr"\
        )
    }
}

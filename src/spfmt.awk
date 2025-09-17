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
    #==========#
    # METADATA #
    #==========#

    # TODO: Find better home for these. Perhaps sed these in makefile?
    # Program metadata.
    PROGRAM_NAME = "spfmt"
    VERSION = "0.1.0 (pre-release)"

    #========================#
    # IMMEDIATE CLI HANDLING #
    #========================#

    # Handle help and version options first, which exit early.
    if (show_help) {
        if (DEBUG_MODE) {
            print "[DEBUG] Help requested."
        }

        print_help()
    }
    else if (show_version) {
        if (DEBUG_MODE) {
            print "[DEBUG] Version requested."
        }

        print_version()
    }

    #=======================#
    # CLI OVERRIDE CHECKING #
    #=======================#

    # Default config variables, overrideable via both CLI or .editorconfig file.
    default_indent_size = 4
    default_indent_char = "space"

    #/**
    # * Individual parameter override flags.
    # *
    # * These start at 0, indicating no parameters were passed/found before run time.
    # * If param is not null at start, means a value was passed and flag is flipped to 0.
    # * Otherwise, look for non-overriden params indiviudally in a .editorconfig file.
    # * Last resort is sane defaults set above if no .editorconfig file can be located.
    # */
    indent_char_overriden = 0
    indent_size_overriden = 0

    # If the indent_char was set before runtime, try to resolve it or bail.
    if (indent_char) {
        if (resolve_indent_char() == 0) {
            indent_char_overriden = 1

            if (DEBUG_MODE) {
                print "[DEBUG] CLI Supplied indent character has been accepted."
            }
        } else {
            if (DEBUG_MODE) {
                print "[DEBUG] CLI Supplied indent character is not valid. Exiting..."
            }

            exit 2
        }
    }

    # If the indent_size was set before runtime, ensure it is a number or bail.
    if (indent_size) {
        if (ensure_indent_size() == 0) {
            indent_size_overriden = 1

            if (DEBUG_MODE) {
                print "[DEBUG] CLI Supplied indent size has been accepted."
            }
        } else {
            if (DEBUG_MODE) {
                print "[DEBUG] CLI Supplied indent size is not valid. Exiting..."
            }

            exit 2
        }
    }

    #/**
    # * In-place flag, files will be modified directly with backups.
    # * If the value is not set, it gets defaulted to off (prints to stdout.)
    # */
    if(!in_place) {
        in_place = 0
    }

    #=========#
    # GLOBALS #
    #=========#

    # Current indentation level, used to track depth.
    current_level = 0
    previous_file = ""
    previous_file = ""  # Explicitly initialize as empty string.
    output_file = ""    # Initialize output file.

    #================#
    # CONFIG LOADING #
    #================#

    #/**
    # * If no CLI parameters were passed for formatting then look for a
    # * .editorconfig file before resorting to sane defaults.
    # */
    if (indent_char_overriden == 0 || indent_size_overriden == 0) {
        if (DEBUG_MODE) {
            if (indent_char_overriden == 0) {
                print "[DEBUG] Missing indent char from CLI." > "/dev/stderr"
            }
            if (indent_size_overriden == 0) {
                print "[DEBUG] Missing indent size from CLI." > "/dev/stderr"
            }
            print "[DEBUG] Attempting to load .editorconfig file." > "/dev/stderr"
        }

        # Looks for a .editorconfig and only updates params not passed via CLI.
        load_config_file()

        # Resort to sane defaults if no overrides provided via CLI or .editorconfig file.
        if (indent_char_overriden == 0) {
            if (DEBUG_MODE) {
                print "[DEBUG] No .editorconfig formatting options found for indent char." > "/dev/stderr"
            }

            # Indents will be a space.
            indent_char = " "

            if (DEBUG_MODE) {
                print "[DEBUG] Resorting to sane default of space indentation." > "/dev/stderr"
            }
        }
        if (indent_char_overriden == 0) {
            if (DEBUG_MODE) {
                print "[DEBUG] No .editorconfig formatting options found for indent size." > "/dev/stderr"
            }

            indent_size = "4"

            if (DEBUG_MODE) {
                print "[DEBUG] Resorting to sane default of indent size of 4" > "/dev/stderr"
            }
        }
    }

    # Print final settings for formatting.
    if (DEBUG_MODE) {
        print "[DEBUG] Final formatting settings" > "/dev/stderr"
        print "[DEBUG]     indent size: " indent_size > "/dev/stderr"
        # TODO: Resolve this char back to a word rather than a char.
        print "[DEBUG]     indent char: " indent_char > "/dev/stderr"
        # TODO: Add configuration for line ending.
        # print "[DEBUG] line-ending: "
    }

}

# Prints the current file name in debug mode and prepares the output file.
FILENAME != previous_file {
    previous_file = FILENAME
    if (DEBUG_MODE) {
        print "[DEBUG] Current input file: " FILENAME > "/dev/stderr"
    }

    output_file = FILENAME ".tmp"
    if (DEBUG_MODE) {
        print "[DEBUG] Output file will be: " output_file > "/dev/stderr"
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
        printf("[DEBUG] End found, level now %d\n", current_level) > "/dev/stderr"
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0)) > output_file
    next
}

# Handle scope-starting keywords, increase indentation level after printing.
/^[ \t]*(Describe|Context|It|Before|After|BeforeAll|AfterAll|BeforeEach|AfterEach)[ \t]/ {
    if (DEBUG_MODE) {
        printf("[DEBUG] Block keyword found: %s, level %d\n", $1, current_level) > "/dev/stderr"
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0)) > output_file
    current_level++
    next
}

# Handle statement keywords, maintain current indentation level.
/^[ \t]*(When|The|Skip|Pending|Todo)[ \t]/ {
    if (DEBUG_MODE) {
        printf("[DEBUG] Statement keyword found: %s, level %d\n", $1, current_level) > "/dev/stderr"
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0)) > output_file
    next
}

# Default case, handle all other lines such as comments.
{
    if (DEBUG_MODE) {
        printf("[DEBUG] Other line, maintaining level %d\n", current_level) > "/dev/stderr"
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0)) > output_file
}

# Dynamically create indentation string for any given level.
function create_indent(    indent, i) {
    indent = ""

    for (i = 0; i < current_level * indent_size; i++) {
        indent = indent indent_char
    }

    return indent
}

# Ensures that a given indent size is a valid integer.
function ensure_indent_size() {
    if (indent_size ~ /^[0-9]+$/) {
        if (DEBUG_MODE) {
            print "[DEBUG] Indent size of " indent_size " is valid." > "/dev/stderr"
        }

        return 0
    } else {
        print "[ERROR] Indent size of " indent_size " was not an integer."

        return 1
    }
}

# Resolves a given string, if supported, to a literal character for indenting.
function resolve_indent_char() {
    # Only used in debug mode print out.
    old_indent_char = indent_char

    if (indent_char == "space") {
        indent_char = " "
    } else if (indent_char == "tab") {
        indent_char = "\t"
    } else {
        print "[ERROR] Indent character not supported. Try 'space' or 'tab' instead."

        return 1
    }

    if (DEBUG_MODE) {
        print "[DEBUG] Indent char of " old_indent_char " was resolved." > "/dev/stderr"
    }

    return 0
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
        "    -i, --in-place        Edit files in-place.\n"\
    )
    printf(\
        "    -s, --indent-size N   Set indentation size (default: %d)\n",
        default_indent_size\
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
        printf("[DEBUG] Processing complete. Final level: %d\n", current_level) > "/dev/stderr"
    }

    if (current_level != 0) {
        printf("[ERROR] Unmatched blocks detected (level %d).\n", current_level)
    }

    close(output_file)

    previous_file = FILENAME
}

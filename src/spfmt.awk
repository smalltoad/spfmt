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
        if (DEV_MODE) {
            print "[DEBUG] Help requested."
        }

        print_help()
    } else if (show_version) {
        if (DEV_MODE) {
            print "[DEBUG] Version requested."
        }

        print_version()
    } else if (DEV_MODE) {
        print "[DEBUG] Starting spfmt"
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
        in_place = 1
    }

    #/**
    # * Should always get an output path from cli/at runtime, but if not assume
    # * /var/tmp/ for fallback, this is not a great option but lets spfmt run.
    # */
    if(!OUTPUT_PATH) {
        OUTPUT_PATH = "/var/tmp/"
    }

    #=========#
    # GLOBALS #
    #=========#

    # Temporary files for atomic writing is stored in OUTPUT_PATH.
    #OUTPUT_PATH = "/var/tmp/spfmt/"

    # Current indentation level, used to track depth.
    current_level = 0
    previous_file = ""  # Explicitly initialize as empty string.
    output_file = ""    # Initialize output file.
    consecuative_empty_lines = 0

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
                print "[DEBUG] No supplied indent char from CLI." > "/dev/stderr"
            }
            if (indent_size_overriden == 0) {
                print "[DEBUG] No supplied indent size from CLI." > "/dev/stderr"
            }
            print "[DEBUG] Attempting to load .editorconfig file before resorting to defaults." \
                > "/dev/stderr"
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

#/**
# * Only runs at the start of a file being processed that is NOT the first.
# * This means when spfmt handles one file this case will never trigger!
# * Handles flushing the previous run that just finished processing.
# */
FNR == 1 && NR != 1 {
    if (DEV_MODE) {
        print "[DEBUG] Case 'FNR == 1 && NR != 1' triggered."
    }

    if (DEBUG_MODE) {
        printf("[DEBUG] Finished processing: %s\n", previous_file) > "/dev/stderr"
    }

    # Flush the file that was just processed before moving onto the next.
    flush()
}

# Runs at the start of EVERY new file that spfmt processes. Runs on file "transiton".
FILENAME != previous_file {
    if (DEV_MODE) {
        print "[DEBUG] Case 'FILENAME != previous_file' triggered."
    }

    if (DEBUG_MODE) {
        print "[DEBUG] Current input file being processed: " FILENAME > "/dev/stderr"
    }

    # Prepare output file.
    output_file = OUTPUT_PATH FILENAME ".tmp"
    if (DEBUG_MODE) {
        print "[DEBUG] Temporary output file will be: " output_file > "/dev/stderr"
    }

    # Keep track of previous filename to figure when this scope should trigger.
    previous_file = FILENAME
}

# Handles empty lines, trimes whitespace.
/^[ \t]*$/ {
    if (DEV_MODE) {
        printf("[DEBUG] Empty line found, level now %d\n", current_level) > "/dev/stderr"
    }

    # Do not print here! Print after more chars are found first.
    #print trim_line($0) > output_file

    consecuative_empty_lines += 1
    next
}

# Handle 'End' statements which result in an decrease in indentation level.
/^[ \t]*End[ \t]*$/ {
    current_level = (current_level > 0) ? current_level - 1 : 0

    if (DEV_MODE) {
        printf("[DEBUG] End found, level now %d\n", current_level) > "/dev/stderr"
    }

    printf("%s%s%s\n", create_newlines(), create_indent(current_level), trim_line($0)) > output_file

    # Reset consecuative empty lines.
    consecuative_empty_lines = 0

    next
}

# Handle scope-starting keywords, increase indentation level for nested scope.
/^[ \t]*(Describe|Context|It|Before|After|BeforeAll|AfterAll|BeforeEach|AfterEach)[ \t]/ {
    if (DEV_MODE) {
        printf("[DEBUG] Block keyword found: %s, level %d\n", $1, current_level) > "/dev/stderr"
    }

    printf("%s%s%s\n", create_newlines(), create_indent(current_level), trim_line($0)) > output_file

    current_level++
    # Reset consecuative empty lines.
    consecuative_empty_lines = 0

    next
}

# Handle statement keywords, maintain current indentation level.
/^[ \t]*(When|The|Skip|Pending|Todo)[ \t]/ {
    if (DEV_MODE) {
        printf("[DEBUG] Statement keyword found: %s, level %d\n", $1, current_level) > "/dev/stderr"
    }

    printf("%s%s%s\n", create_newlines(), create_indent(current_level), trim_line($0)) > output_file

    # Reset consecuative empty lines.
    consecuative_empty_lines = 0

    next
}

# Default case, handle all other lines such as comments.
{
    if (DEV_MODE) {
        printf("[DEBUG] Other line, maintaining level %d\n", current_level) > "/dev/stderr"
    }

    # Not a empty line! Reset instead of increment.
    consecuative_empty_lines = 0

    printf("%s%s%s\n", create_newlines(), create_indent(current_level), trim_line($0)) > output_file
}

ENDFILE {
    # Reset consecuative empty lines.
    consecuative_empty_lines = 0

    # Print last newline to end of file.
    print "" > output_file
}

# After everything has been processed, NOT end of file but end of all files.
END {
    # When END is reached, if number of records are greater than 0, flush the last file.
    if (NR > 0) {
        if (DEBUG_MODE) {
            printf("[DEBUG] Finished processing: %s\n", previous_file) > "/dev/stderr"
        }

        flush()
    }

    if (DEBUG_MODE) {
        printf("[DEBUG] All files processed. Ending.\n") > "/dev/stderr"
    }
}

# Writes the formatted content out to either file or file descriptor 1.
function flush() {
    if (current_level != 0) {
        printf("[ERROR] Unmatched blocks detected! Will not print out.\n")
    } else {
        #/**
        # * NOTE: Must close atomic file before attempting to read from it in the
        # * following write operations. The file will be re-opened,closed and
        # * cleaned up in the clean_up function upon exit.
        # */
        close(output_file)

        # Logic for determining where the final output needs to go.
        if (in_place == 0) {
            # If in place then copy the contents of the .tmp file to the original.
            write_in_place()
        } else {
            # Otherwise spit to stdout.
            write_to_stdin()
        }

        # Tidy the workspace.
        clean_up()
    }
}

# In place flag was not true, so write out to consol.
function write_to_stdin() {
    if (DEBUG_MODE) {
        printf("[DEBUG] Writing contents of %s to stdin...\n", output_file) > "/dev/stderr"
    }

    line = ""
    while ((getline line < output_file) > 0) {
        print line  # Goes to stdout by default.
    }
}

function write_in_place() {
    if (DEBUG_MODE) {
        printf("[DEBUG] write_in_place is stubbed for now.\n") > "/dev/stderr"
        return
    }
}

# Dynamically create newlines.
function create_newlines(    _newlines) {
    _newlines=""

    for (i = 0; i < consecuative_empty_lines; i++) {
        _newlines = _newlines "\n"
    }

    # Reset consecuative empty lines.
    consecuative_empty_lines = 0

    return _newlines
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
        if (DEV_MODE) {
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
        print "[DEBUG] Indent char of " old_indent_char " was resolved correctly." > "/dev/stderr"
    }

    return 0
}

function clean_up() {
    close(output_file)
    # TODO: Uncomment this line. Currently testing outputs.
    #system("rm -f " output_file)
}

function print_help() {
    printf("%s - Shellspec Formatter\n\n", PROGRAM_NAME)

    printf("DESCRIPTION:\n")
    printf(\
        "\tFormats ShellSpec test files with consistent indentation and structure.\n"\
    )
    printf(\
        "\tIf no files are specified, reads from stdin and writes to stdout.\n"\
    )
    printf(\
        "\tSupports .editorconfig standard and reads from [*.sh] section.\n\n"\
    )

    printf("USAGE:\n")
    printf("\t%s [OPTIONS] [FILES...]\n", PROGRAM_NAME)
    printf("\t%s --help\n", PROGRAM_NAME)
    printf("\t%s --version\n\n", PROGRAM_NAME)

    printf("OPTIONS:\n")
    printf(\
        "\t-i, --in-place        Edit files in-place, directly overwirting the contents.\n"\
    )
    printf(\
        "\t-s, --indent-size N   Set indentation size (default: 2)\n"\
    )
    printf(\
        "\t-c, --indent-char C   Set indentation character (default: space)\n"\
    )
    printf("\t-d, --debug           Enable debug output to stderr\n")
    printf("\t-dd, --dev-mode       Enable dev mode, more verbose than debug mode\n")
    printf("\t-h, --help            Show this help message\n")
    printf("\t-v, --version         Show version information\n\n")

    printf("EXAMPLES:\n")
    printf(\
        "\t%s test_spec.sh                     # Format to stdout\n",
        PROGRAM_NAME\
    )
    printf(\
        "\t%s -i spec/*.sh                     # Format multiple files in-place in Shellspec folder\n",
        PROGRAM_NAME\
    )
    printf(\
        "\t%s -s 3 spec/my_spec.sh             # Custom indentation\n",
        PROGRAM_NAME\
    )
    printf(\
        "\t%s -c tab spec/my_spec.sh           # Switch from spaces to tabs\n",
        PROGRAM_NAME\
    )
    printf(\
        "\tcat test_spec.sh | %s > output.txt  # From stdin redirecting stdout to file\n\n",
        PROGRAM_NAME\
    )

    exit 0
}

function print_version() {
    printf("%s v%s\n", PROGRAM_NAME, VERSION)
    exit 0
}

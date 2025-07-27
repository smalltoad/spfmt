#!/usr/bin/awk -f
# File: spfmt.awk
# Description: POSIX-compliant AWK script to format ShellSpec test files.
# Author: Joseph Mowery <mowery.joseph@outlook.com>
# Usage: awk -f spfmt.awk input_file.sh

BEGIN {
    # ======================= #
    # VARIABLE INITIALIZATION #
    # ======================= #

    # Program metadata
    PROGRAM_NAME = "spfmt"
    VERSION = "1.0.0"

    # Default configuration variables, overriddable via .editorconfig or CLI.
    indent_size = 4
    indent_char = " "

    # Current indentation level, used to track depth.
    current_level = 0

    # Flags/options spfmt handles.
    debug = 0 # Debug mode flag, turns on verbose output.
    defaults_overriden = 0 # Flag to track if defaults were overridden.
    in_place = 0 # In-place flag, files will be modified directly with backups.
    show_help = 0
    show_version = 0

    # Files found in args during parsing.
    file_count = 0

    # ============================= #
    # PARSE AND CONFIGURATION SETUP #
    # ============================= #

    # Process command line arguments.
    parse_arguments()

    # Immediately after parsing, check for debug mode first.
    if (debug) { print "[DEBUG] Debug mode enabled." > "/dev/stderr" }

    # Handle help and version options first, then exit.
    if (show_help) {
        if (debug) {
            print "[DEBUG] Help requested." > "/dev/stderr"

            if (defaults_overriden != 0 || file_count > 0) {
                print\
                    "[DEBUG] CLI options were provided, but help option takes preceedence." > "/dev/stderr"
            }
        }

        print_help()
    }
    else if (show_version) {
        if (debug) {
            print "[DEBUG] Version requested." > "/dev/stderr"

            if (defaults_overriden != 0 || file_count > 0) {
                print\
                    "[DEBUG] CLI options were provided, but version option takes preceedence." > "/dev/stderr"
            }
        }

        print_version()
    }

    # CLI modifications will take preference over config file.
    if (defaults_overriden == 0) {
        if (debug) {
            print "[DEBUG] No CLI formatting options found." > "/dev/stderr"
            print "[DEBUG] Searching for .editorconfig file." > "/dev/stderr"
        }

        load_config_file()
    }

    # Print final settings for formatting
    if (debug) {
        print "[DEBUG] Final formatting settings"
        print "[DEBUG] indent size:"
        print "[DEBUG] indent char:"
        print "[DEBUG] line-ending:"
    }

    # ============= #
    # PROCESS FILES #
    # ============= #

    # If no files specified, process stdin
    if (file_count == 0) {
        if (debug) {
            print "[DEBUG] No files found from CLI." > "/dev/stderr"
            print "[DEBUG] Processing from stdin instead..." > "/dev/stderr"
        }

        process_input()
    }
    else {
        # Process each file from CLI
        process_files()
    }
}

# Parse command line arguments using ARGC/ARGV
function parse_arguments(i, arg) {
    for (i = 1; i < ARGC; i++) {
        arg = ARGV[i]

        # Handle options first
        if (arg == "-h" || arg == "--help") {
            show_help = 1
            ARGV[i] = "" # Similar to shift, but removes from $@.
        }
        else if (arg == "-v" || arg == "--version") {
            show_version = 1
            ARGV[i] = ""
        }
        else if (arg == "-d" || arg == "--debug") {
            debug = 1
            ARGV[i] = ""
        }
        else if (arg == "-i" || arg == "--in-place") {
            in_place = 1
            ARGV[i] = ""
        }
        else if (arg == "-s" || arg == "--indent-size") {
            if (i + 1 < ARGC && ARGV[i + 1] ~ /^[0-9]+$/) {
                defaults_overriden = 1
                indent_size = ARGV[i + 1]
                ARGV[i] = ""
                ARGV[i + 1] = ""
                i++ # Skip the argument two ahead
            }
            else {
                print\
                    "[ERROR] -s|--indent-size requires a positive integer" > "/dev/stderr"
                exit 2
            }
        }
        else if (arg == "-c" || arg == "--indent-char") {
            if (i + 1 < ARGC) {
                defaults_overriden = 1
                indent_char = ARGV[i + 1]
                ARGV[i] = ""
                ARGV[i + 1] = ""
                i++ # Skip the argument two ahead
            }
            else {
                print\
                    "[ERROR] -c|--indent-char requires a character" > "/dev/stderr"
                exit 2
            }
        }
        else if (arg ~ /^-/) {
            printf("Error: Unknown option: %s\n", arg > "/dev/stderr")
            print "Use --help for usage information" > "/dev/stderr"
            exit 2
        }
        else {
            # This is a file argument
            file_list[file_count] = arg
            file_count++
            ARGV[i] = "" # Prevent AWK from auto-processing it
        }
    }
}

# Handle empty lines, preserve them as-is
/^[ \t]*$/ {
    print $0
    next
}

# Handle 'End' statements, decrease indentation level
/^[ \t]*End[ \t]*$/ {
    current_level = (current_level > 0) ? current_level - 1 : 0

    if (debug) {
        printf("# End found, level now %d\n", current_level > "/dev/stderr")
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    next
}

# Handle block-starting keywords, increase indentation after printing
/^[ \t]*(Describe|Context|It|Before|After|BeforeAll|AfterAll|BeforeEach|AfterEach)[ \t]/ {
    if (debug) {
        printf(\
            "# Block keyword found: %s, level %d\n",
            $1,
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    current_level++
    next
}

# Handle statement keywords, maintain current indentation
/^[ \t]*(When|The|Skip|Pending|Todo)[ \t]/ {
    if (debug) {
        printf(\
            "# Statement keyword found: %s, level %d\n",
            $1,
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
    next
}

# Default case, handle all other lines
{
    if (debug) {
        printf(\
            "# Other line, maintaining level %d\n",
            current_level > "/dev/stderr"\
        )
    }

    printf("%s%s\n", create_indent(current_level), trim_line($0))
}

# Create indentation string for given level
function create_indent(level, indent, i) {
    indent = ""

    for (i = 0; i < level * indent_size; i++) { indent = indent indent_char }

    return indent
}

# Remove leading and trailing whitespace
function trim_line(str, result) {
    result = str
    gsub(/^[ \t]+/, "", result)
    gsub(/[ \t]+$/, "", result)
    return result
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
    if (debug) {
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

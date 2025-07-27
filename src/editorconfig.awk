#!/usr/bin/awk -f

# File: editorconfig.awk
# Description: POSIX-compliant AWK script to load in an .editorconfig file.
# Author: Joseph Mowery <mowery.joseph@outlook.com>
# Usage: awk editorconfig.awk -f parse.awk input_file.sh

#===========#
# SEARCHERS #
#===========#

# Main function that will attempt to find and parse .editorconfig files.
function load_config_file() {
    # Get the current directory.
    current_dir = get_current_dir()

    # Attempt to find a suitable .editorconfig file.
    editorconfig_path = _find_editorconfig(current_dir)

    if (editorconfig_path) {
        if (debug) {
            print "[DEBUG] Found .editorconfig at: " editorconfig_path > "/dev/stderr"
        }
        # Parse the located .editorconfig file.
        _parse_editorconfig(editorconfig_path)
    } else {
        if (debug) {
            print "[DEBUG] No .editorconfig file found, resorting to fallbacks." > "/dev/stderr"
        }
    }
}

# Crawls up the directory structure looking looking for .editorconfig files.
function _find_editorconfig(start_dir, path, cmd_file_check, is_file, cmd_read_check, is_readable, result, parent_dir)
{
    path = start_dir

    if (debug) {
        print\
            "[DEBUG] Starting .editorconfig discovery from: "\
                path > "/dev/stderr"
    }

    # Search up the directory tree until root is reached.
    while (path != "/" && path != "") {
        # Append "/.editorconfig" to current search path
        path_to_check = path "/.editorconfig"

        if (debug) {
            print\
                "[DEBUG] Checking for .editorconfig at: "\
                    to_check > "/dev/stderr"
        }

        # Does the path lead to a file?
        is_file = check_file(path_to_check)

        if (is_file) {
            if (debug) {
                print\
                    "[DEBUG] Found .editorconfig at: "\
                        path_to_check > "/dev/stderr"
            }

            # Is the file readable?
            is_readable = check_readable(path_to_check)

            if (debug) {
                print\
                    "[DEBUG] The .editorconfig is "\
                        is_readable\
                        ? "readable."\
                        : "un-readable." > "/dev/stderr"
            }

            if (result) {
                # File exists, file is readable, now check if it's the root config.
                if (_is_root_config(path_to_check)) {
                    if (debug) {
                        print\
                            "[DEBUG] Found root .editorconfig at: "\
                                path_to_check > "/dev/stderr"
                    }

                    return path_to_check
                }
                else {
                    if (debug) {
                        print\
                            "[DEBUG] Found non-root .editorconfig at: "\
                                path_to_check > "/dev/stderr"
                    }

                    # TODO: Accumulate all non-root options, and handle.
                    return path_to_check
                }
            }
        }

        # No match. move up one directory and keep looking
        parent_dir = get_parent_directory(path)

        if (parent_dir == path) {
            # We've reached the root or can't go further
            break
        }

        path = parent_dir
    }

    # No .editorconfig found, return nothing
    return ""
}

# ================= #
# PARSING FUNCTIONS #
# ================= #

# Check if .editorconfig file has root = true
function _is_root_config(config_file, line, found_root) {
    # Flag for root found
    found_root = 0

    # Read through the entire file looking for root = true
    while ((getline line < config_file) > 0) {
        # Remove leading/trailing whitespace
        gsub(/^[ \t]+/, "", line)    # Strip leading spaces and tabs
        gsub(/[ \t]+$/, "", line)    # Strip trailing spaces and tabs

        # Skip empty lines and comments
        if (line == "" || line ~ /^#/) { continue }

        # Remove inline comments
        sub(/#.*$/, "", line)

        # Stop processing at a section header
        # root = true MUST BE AT TOP LEVEL
        if (line ~ /^\[.*\]$/) { break }

        # Look for root = true (case insensitive)
        # This pattern handles various whitespace scenarios around the equals sign
        if (tolower(line) ~ /^root[ \t]*=[ \t]*true[ \t]*$/) {
            found_root = 1
            break # Found final config file, early exit
        }
    }

    close(config_file) # Always close the file handle
    return found_root
}

# Parse .editorconfig file and extract relevant settings
function _parse_editorconfig(config_file, line, section, in_shell_section, key, value) {
    if (debug) {
        print "[DEBUG] Parsing .editorconfig file: " config_file > "/dev/stderr"
    }

    section = ""
    in_shell_section = 0

    # Read the config file line by line
    while ((getline line < config_file) > 0) {
        # Remove leading/trailing whitespace
        gsub(/^[ \t]+/, "", line)    # Strip leading spaces and tabs
        gsub(/[ \t]+$/, "", line)    # Strip trailing spaces and tabs

        # Skip empty lines and comments
        if (line == "" || line ~ /^[#;]/) {
            continue
        }

        # Check for section headers [section]
        if (line ~ /^\[.*\]$/) {
            section = line
            gsub(/^\[|\]$/, "", section)  # Remove brackets

            if (debug) {
                print "[DEBUG] Found section: [" section "]" > "/dev/stderr"
            }

            # Check if this section applies to shell files
            in_shell_section = section_matches_shell_files(section)

            if (debug && in_shell_section) {
                print "[DEBUG] Section matches shell files" > "/dev/stderr"
            }

            continue
        }

        # Parse key=value pairs
        if (line ~ /=/ && in_shell_section) {
            # Split on first equals sign
            key = line
            value = line

            sub(/=.*$/, "", key)    # Remove everything after first =
            sub(/^[^=]*=/, "", value)  # Remove everything before first =

            gsub(/^\[/, "", section)  # Remove opening bracket
            gsub(/\]$/, "", section)  # Remove closing bracket

            if (debug) {
                print "[DEBUG] Found property: " key " = " value > "/dev/stderr"
            }

            # Apply the configuration
            apply_config_property(key, value)
        }
    }

    close(config_file)
}

# ================== #
# UTILITIY FUNCTIONS #
# ================== #

# Gets the absoulte path of the current working directory from the process environments variables.
# Falls back to "." if pwd is unavailable.
function get_current_dir(current_dir) {
    current_dir = ENVIRON["PWD"]

    if (!current_dir || !test_directory(current_dir)) { current_dir = "." }

    return current_dir
}

# Get parent directory of given path.
function get_parent_directory(path, cmd, result) {
    # Run dirname on current path
    cmd = "dirname \"" path "\""
    # Pipe output of subshell into result
    cmd | getline result
    close(cmd)

    return result
}

# Test if file exists using test command, must be string literal.
function check_file(file_to_check, is_file) {
    cmd_file_check = "test -f \"" file_to_check "\""
    is_file = system(cmd_file_check)

    return is_file
}

# Test if a file is readable, must be string literal.
function test_readable(file_to_check, is_readable) {
    # Test if file exists using test command
    cmd_read_check = "test -r \"" file_to_check "\""
    is_readable = system(cmd_read_check)

    return (is_readable == 0)
}

function test_directory(current_dir) {
    cmd = "test -d \"" current_dir "\""

    # Execute command and capture exit code
    is_directory = system(cmd)

    return (is_directory == 0)
}

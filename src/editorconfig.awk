#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: POSIX-compliant AWK script to load in an .editorconfig file.
# File: .editorconfig.awk
# License: GNU GPLv3

#=========#
# LOADERS #
#=========#

#/**
# * DESCRIPTION
# * Intended entry function to this module that will attempt to find and return
# * .editorconfig files. Will stop crawling when either root config is found
# * or root directory is reached. Prioritizes config files closer to root.
# *
# * @param indent_size {passed}
# *     Indent size read from a found .editorconfig file.
# *
# * @param indent_char {passed}
# *     Indent char read from a found .editorconfig file.
# *
# * @param _current_dir {local}
# *     Current directory temporary variable. Starts from current working
# *     directory and updates based on the return of _find_editorconfig().
# *     Either gets replaced with the parent directory of the return or will
# *     hold an empty string once root is reached.
# *
# * @param _editorconfig_path {local}
# *     Return from _find_editor_config(), either a path to the found
# *     .editorconfig file or an empty string. In the event of an empty string
# *     spfmt resorts to fallbacks in its own file.
# */
function load_config_file(indent_size, indent_char,    _current_dir, _editorconfig_path, _configs_found, _root_found, _search_flag)
{
    # Clear local variables in case they've been passed.
    delete _current_dir
    delete _editorconfig_path
    delete _configs_found
    delete _root_found
    delete _search_flag

    # Search parameters
    _current_dir = get_current_dir()
    _search_flag = 1
    _configs_found = 0
    _root_found = 0

    if (debug) {
        print\
            "[DEBUG] Starting .editorconfig discovery from: "  _current_dir
    }

    # Walks up the directory structure from current working directory.
    # Looks for a .editorConfig file at each directory level, then will
    # parse out any expected settings.
    while (_search_flag) {
        # Attempt to find a .editorconfig file by crawling up the filesystem.
        _editorconfig_path = _find_editorconfig(_current_dir)

        # Non-empty string indicates that a .editorConfig file has been found.
        if (_editorconfig_path != "") {
            _configs_found += 1

            if (debug) {
                print "[DEBUG] Found .editorconfig at: " _editorconfig_path
            }

            # Parse the located .editorconfig file.
            _parse_editorconfig(_editorconfig_path, indent_size, indent_char)

            if (debug) {
                if (indent_char) {
                    print "[DEBUG] Indent character was found at " _editorconfig_path
                    print "[DEBUG] Indent character now set to: " indent_char
                } else {
                    print "[DEBUG] Indent character was not found at " _editorconfig_path
                }

                if (indent_size) {
                    print "[DEBUG] Indent size was found at " _editorconfig_path
                    print "[DEBUG] Indent size now set to: " indent_size
                } else {
                    print "[DEBUG] Indent size was not found at " _editorconfig_path
                }
            }

            # Is the file we found root? Return of 1 indicates non-root file.
            if (_check_is_root(_editorconfig_path) == 1) {
                # Move up a directory before iterating again.
                _current_dir = get_parent_directory()
            } else {
                if (debug) {
                    print "[DEBUG] Root found, stopping .editorConfig file searching."
                }

                # Stop searching for more
                _search_flag = 0
            }

        # Otherwise, we hit root... Decide the next action based on flags.
        } else {
            # No configs found the entire search.
            if (_configs_found == 0) {
                if (debug) {
                    print "[DEBUG] No .editorconfig file found, resorting to fallbacks."
                }
            # Debug prints for discovered settings.
            } else {
                if (debug) {
                    if (indent_char) {
                        print "[DEBUG] Indent character was found to be: " indent_char
                    } else {
                        print "[DEBUG] Indent char not set, resorting to safe fallback."
                    }

                    if (indent_size) {
                        print "[DEBUG] Indent size was found to be: " indent_size
                    } else {
                        print "[DEBUG] Indent size not set, resorting to safe fallback"
                    }
                }
            }

            # Stop searching for more
            _search_flag = 0
        }
    }
}

#/**
# * Manages the functions required to crawl up the directory structure,
# * determine if the root .editorconfig file has been found and will call parse
# * on found .editorconfig files.
# *
# * @param start_dir {passed}
# *     Starting path to begin crawling from.
# *
# * @param _curr_path {local}
# *      Tracks current path and changes as ascending.
# *
# * @param _file_path_to_check {local}
# *      Concat of _curr_path and '/.editorconfig' to form target .
# *
# * @param _is_file {local}
# *     Flag returned by file checker function, 0 if file found and 1 otherwise.
# *
# * @param _is_readable {local}
# *     Flag returned by is_readable function, 0 if readable and 1 otherwise.
# *
# * @return _file_path_to_check
# *     Path to the found .editorconfig file. Might not be root, responsibility
# *     falls on calling function to iterate with dirname to aggregate settings
# *     across multiple non-root editorconfig files.
# */
function _find_editorconfig(start_dir,    _curr_path, _file_path_to_check, _cmd_file_check, _is_file, _cmd_read_check, _is_readable, _result, _parent_dir)
{
    # Clear local variables in case they've been passed.
    delete _curr_path
    delete _cmd_file_check
    delete _is_file
    delete _cmd_read_check
    delete _is_readable
    delete _result
    delete _parent_dir

    _curr_path = start_dir

    # Search up the directory tree until root is reached.
    while (_curr_path != "/" && _curr_path != "") {
        # Append "/.editorconfig" to current search path.
        _file_path_to_check = _curr_path "/.editorconfig"

        if (debug) {
            print\
                "[DEBUG] Checking for .editorconfig at: "\
                    _file_path_to_check > "/dev/stderr"
        }

        # Does the path lead to a file?
        _is_file = test_file(_file_path_to_check)

        # Was there a .editorconfig file in the directory?
        if (_is_file == 0) {
            if (debug) {
                print\
                    "[DEBUG] Found .editorconfig at: "\
                        _file_path_to_check > "/dev/stderr"
            }

            _is_readable = test_readable(_file_path_to_check)

            if (debug) {
                print\
                    "[DEBUG] The .editorconfig is "\
                        _is_readable\
                        ? "readable."\
                        : "un-readable." > "/dev/stderr"
            }

            # Is the file readable?
            if (_is_readable == 0) {
                # File exists, file is readable, now return!
                if (debug) {
                    print\
                        "[DEBUG] Found readable .editorconfig at: "\
                            _file_path_to_check > "/dev/stderr"
                }

                return _file_path_to_check

            } else {
                # File exists, but IS NOT readable?
                if (debug) {
                    print\
                        "[DEBUG] Found UNREADABLE .editorconfig at: "\
                            _file_path_to_check > "/dev/stderr"
                }
            }
        }

        # No match in _curr_path !
        # Move up one directory from original start_dir and keep looking.
        _parent_dir = get_parent_directory(start_dir)

        if (_parent_dir == start_dir) {
            # We've reached the root or can't go further.
            return ""
        }

        _curr_path = _parent_dir
    }

    # No .editorconfig found, return empty string.
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
# Falls back to "." if pwd is unavailable or not a real directory on the system.
function get_current_dir(current_dir) {
    current_dir = ENVIRON["PWD"]

    if (!current_dir || !test_directory(current_dir)) { current_dir = "." }

    return current_dir
}

# Get parent directory of given path.
function get_parent_directory(path, cmd, _result) {
    # Run dirname on current path
    cmd = "dirname \"" path "\""
    # Pipe output of subshell into _result
    cmd | getline _result
    close(cmd)

    return _result
}

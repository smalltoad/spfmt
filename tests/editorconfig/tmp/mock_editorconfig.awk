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

# ================== #
# UTILITIY FUNCTIONS #
# ================== #

# Gets the absoulte path of the current working directory from the process environments variables.
# Falls back to "." if pwd is unavailable or not a real directory on the system.

# Get parent directory of given path.

#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the load_config_file function in the editorconfig.awk module.
# File: load_config_file_test.bats
# License: GNU GPLv3

#=====================================#
# PSEUDO-CODE FUNCTION REPRESENTATION #
#=====================================#

# function load_config_file(indent_size, indent_char,    _current_dir, _editorconfig_path, _configs_found, _root_found, _search_flag) {
#     _current_dir = get_current_dir()
#
#     while (_search_flag) {
#         _editorconfig_path = _find_editorconfig(_current_dir)
#
#         if (_editorconfig_path != "") {
#             _configs_found += 1
#
#             _parse_editorconfig(_editorconfig_path, indent_size, indent_char)
#
#            if (_check_is_root(_editorconfig_path) == 1) {
#                _current_dir = get_parent_directory()
#            } else {
#                _search_flag = 0
#            }
#         } else {
#             _search_flag = 0
#         }
#     }
# }

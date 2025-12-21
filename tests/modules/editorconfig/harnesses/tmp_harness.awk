#!/usr/bin/awk -f
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Wrapper for editorconfig.awk function of parse_editorconfig to print results.
#
# [FILE] parse_editorconfig_harness.bats
# [LICENSE] GNU GPLv3
# */

{
    # Normally set in spfmt.awk, note without this the early exit will always be taken
    overrides["indent_size"] = 0
    overrides["indent_char"] = 0

    result = load_config_file()

    # Printed with ":" delimiter, meant for passing to BATS assertion.
    print effective["indent_size"] ":" effective["indent_char"]
}

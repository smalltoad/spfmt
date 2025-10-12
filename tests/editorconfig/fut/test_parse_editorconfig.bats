#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: BATS tests for the _parse_editorconfig function in the editorconfig.awk module.
# File: test_parse_editorconfig.bats
# License: GNU GPLv3
#
# Comandline execution examples:
#     $ bats test_parse_editorconfig.bats
#     $ ./tests/editorconfig/fut/test_parse_editorconfig.bats
# With INFO turned on:
#     $ INFO=1 ./tests/editorconfig/fut/test_parse_editorconfig.bats
# With TAP compliant output:
#     $ bats test_parse_editorconfig.bats --tap

#=====================#
# FUNCTION UNDER TEST #
#=====================#

# function _parse_editorconfig(config_file,    line, in_section, indents, char) {
#    in_section = 1
#
#    while ((getline line < config_file) > 0) {
#        strip_leading_whitespace(line)
#        strip_trailing_whitespace(line)
#
#        if (line == "" || line ~ /^#/) { continue }
#
#        if (line ~ /^\[.*\]$/) {
#            gsub(/^\[|\]$/, "", line)
#
#            if (line == "awk" || line == "spfmt") {
#                in_section = 0
#            } else if (in_section == 0){
#                break
#            }
#
#            continue
#        }
#        if (in_section == 0) {
#            if (line ~ /^indent_size =/) {
#                sub(/^indent_size =/, "", line)
#                indent_size = line
#                continue
#            }
#
#            if (line ~ /^indent_size =/) {
#                sub(/^indent_size =/, "", line)
#                indent_size = line
#                continue
#            }
#        }
#    }
#    close(config_file)
# }

#========#
# SET UP #
#========#

# AWK script containing FUT
script="editorconfig.awk"

# Harness to call specific FUT
harness="parse_editorconfig_harness.awk"

# BATS helpers
load "${BATS_TEST_DIRNAME}/../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../bats_helpers/check_files_helper.bash"

# Color sourcing must live outside setup() to be available in current env.
. "${BATS_TEST_DIRNAME}/../../bats_helpers/colors_helper.bash"

setup_file() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3

    export mocked_script

    # Create mock for test suite.
    mocked_script_path=$(mock_script "${script}:strip_leading_whitespace:strip_trailing_whitespace")
    mocked_script=$(basename -- "${mocked_script_path}")
}

setup() {
    base="$(mktemp -d "/tmp/test_parse_editorconfig.XXXXXX")"
    export input="${base}"
}

teardown_file() {
    rm -rf "${mocked_script_path}"
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

teardown() {
    rm -rf "${base:-}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _parse_editorconfig returns nothing for empty/null path" {
    # Test case that proves robustness, guarding against empty/null input.
    input=" "
    expected=":"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig returns nothing for non-existant path" {
    # Test case that proves robustness, guarding against empty/null input.
    input="${input}/.editorconfig"
    expected=":"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when there is only an AWK section" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[awk]\nindent_size = 2\nindent_char = space" >"${input}"
    vars="indent_size_overriden=0:indent_char_overriden=0"
    expected="2:space"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when AWK sections comes after another" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[txt]\nindent_size = 4\nindent_char = shift\n[awk]\nindent_size = 2\nindent_char = space" >"${input}"
    expected="2:space"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when AWK sections comes before another" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[awk]\nindent_size = 2\nindent_char = space\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    expected="2:space"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when there is both good and bad data" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "bad data\n[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    expected="2:space"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig does not replace previously set indent and character values" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="indent_size=1:indent_char=tab"
    expected="1:tab"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig does not replace runtime overrides on indent and character values" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="indent_size=1:indent_char=tab:indent_size_overriden=1:indent_char_overriden=1"
    expected="1:tab"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -v "${vars}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig does not parse more when defaults are all overriden" {
    # Test case that proves parsing of expected input.
    input="${input}/.editorconfig"
    touch "${input}"
    printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="defaults_overriden=1:indent_size=1:indent_char=tab:indent_size_overriden=1:indent_size_overriden=1"
    expected="1:tab"

    assert_builder \
        -m "${mocked_script}" \
        -h "${harness}" \
        -i "${input}" \
        -v "${vars}" \
        -x "${expected}"
}

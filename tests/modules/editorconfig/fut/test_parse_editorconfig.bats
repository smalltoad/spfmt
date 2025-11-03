#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# BATS tests for the _parse_editorconfig function in the editorconfig.awk module.
#
# [FILE] test_parse_editorconfig.bats
# [LICENSE] GNU GPLv3
# */

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/tmp_folder_helper.bash"

script="editorconfig.awk"
harness="parse_editorconfig_harness.awk"

setup_file() {
    log_test_start

    mock=$(mock_script "${script}" "strip_leading_whitespace:strip_trailing_whitespace")
    export mock
}

setup() {
    # Since each test makes a .editorconfig file, this must not be inside setup_file!
    base="$(get_temp_working_dir)"
    input="${base}/.editorconfig"
    touch "${input}"
}

teardown_file() {
    clean_mock "${mock}"
    log_test_end
}

teardown() {
    rm -rf "${base}"
}

#============#
# TEST CASES #
#============#

@test "[TEST] _parse_editorconfig returns nothing for empty/null path" {
    input=" "
    expected=":"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig returns nothing for non-existant path" {
    input="${base}/.editorconfig"
    expected=":"

    assert_builder \
        -m "${mock}" \
        -h "${harness}" \
        -i "${input}" \
        -x "${expected}"
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when there is only an AWK section" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "[awk]\nindent_size = 2\nindent_char = space" >"${input}"
    vars="indent_size_overriden=0:indent_char_overriden=0"
    expected="2:space"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -v "${vars}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when AWK sections comes after another" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "[txt]\nindent_size = 4\nindent_char = shift\n[awk]\nindent_size = 2\nindent_char = space" >"${input}"
    expected="2:space"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when AWK sections comes before another" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "[awk]\nindent_size = 2\nindent_char = space\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    expected="2:space"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig can find AWK section and return correct values when there is both good and bad data" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "bad data\n[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    expected="2:space"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig does not replace previously set indent and character values" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="indent_size=1:indent_char=tab"
    expected="1:tab"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -v "${vars}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig does not replace runtime overrides on indent and character values" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="indent_size=1:indent_char=tab:indent_size_overriden=1:indent_char_overriden=1"
    expected="1:tab"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -v "${vars}" \
            -x "${expected}"
    }
}

@test "[TEST] _parse_editorconfig does not parse more when defaults are all overriden" {
    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.printf "[awk]\nindent_size = 2\nindent_char = space\n\n[txt]\nindent_size = 4\nindent_char = shift" >"${input}"
    vars="defaults_overriden=1:indent_size=1:indent_char=tab:indent_size_overriden=1:indent_size_overriden=1"
    expected="1:tab"

    # shellcheck disable=SC2031 # Intentionally segmented through BATS subshell.
    {
        assert_builder \
            -m "${mock}" \
            -h "${harness}" \
            -i "${input}" \
            -v "${vars}" \
            -x "${expected}"
    }
}

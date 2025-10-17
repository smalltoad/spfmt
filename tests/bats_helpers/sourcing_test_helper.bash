#!/usr/bin/env bash
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Description:
# BATS helper for shell testing, streamlines test creation and assertions.
# Streamlines
#
# File: sourcing_test_helper.bash
# License: GNU GPLv3

#===================#
# PATHING FUNCTIONS #
#===================#

# Get the root directory of the project.
get_project_root() {
    echo "${BATS_TEST_DIRNAME}/../../../.."
}

# Get the source directory containing ssource code.
get_src_dir() {
    echo "$(get_project_root)/src"
}

# Get the harnesses directory containing test harnesses.
get_harness_dir() {
    echo "${BATS_TEST_DIRNAME}/../harnesses"
}

# Get the BATS test helpers directory.
get_helpers_dir() {
    echo "${BATS_TEST_DIRNAME}/../../../bats_helpers"
}

# Get the tmp directory within a test folder.
get_tmp_dir() {
    echo "${BATS_TEST_DIRNAME}/../../tmp"
}

#====================#
# SOURCING FUNCTIONS #
#====================#

source_script() {
    script_name="$1"
    script_path="$(get_src_dir)/${script_name}"

    if [[ ! -f "${script_path}" ]]; then
        echo "[ERROR] Script not found? ${script_path}" >&2
        return 1
    fi

    . "${script_path}"
}

source_harness() {
    harness_name="$1"
    harness_path="$(get_harness_dir)/${harness_name}"

    if [[ ! -f "${harness_path}" ]]; then
        echo "[ERROR] Harness not found? ${script_path}" >&2
        return 1
    fi

    . "${harness_path}"
}

source_helper() {
    helper_name="$1"
    helper_path="$(get_helpers_dir)/${helper_name}"

    if [[ ! -f "${helper_path}" ]]; then
        echo "[ERROR] Helper not found? ${script_path}" >&2
        return 1
    fi

    # Source the helper
    . "${helper_path}"
}

# Source multiple helpers at once.
source_helpers() {
    for helper_name in "$@"; do
        source_helper "${helper_name}" || return 1
    done
}

#===================#
# LOGGING FUNCTIONS #
#===================#

log_test_start() {
    echo "[START] ${BATS_TEST_FILENAME##*/}" >&3
}

log_test_end() {
    echo "[END] ${BATS_TEST_FILENAME##*/}" >&3
}

# (bash-ism) Export functions so they're available in test files
export -f get_project_root
export -f get_src_dir
export -f get_harness_dir
export -f get_helpers_dir
export -f get_tmp_dir
export -f source_script
export -f source_harness
export -f source_helper
export -f source_helpers
export -f log_test_start
export -f log_test_end

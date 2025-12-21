#!/usr/bin/env bats
#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/******************************************************************************
# [DESCRIPTION]
# BATS tests for the load_config_file function in the editorconfig.awk module.
#
# [FILE] load_config_file_test.bats
# [LICENSE] GNU GPLv3
# *****************************************************************************/

#========#
# SET UP #
#========#

# shellcheck disable=SC2154 # BATS_TEST_DIRNAME is provided by BATS.
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/awk_test_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/persistant_sandbox_helper.bash"
load "${BATS_TEST_DIRNAME}/../../../bats_helpers/sourcing_test_helper.bash"

script="editorconfig.awk"
depend1="file_utils.awk"
depend2="parse.awk"
harness="tmp_harness.awk"

setup_file() {
    log_test_start
}

setup() {
    # Each test gets its own sandbox, trap to ensure it is cleaned up
    trap 'kill_env EXIT' INT TERM
    get_isolated_fs_env

    export NS_PID
}

teardown_file() {
    log_test_end
}

teardown() {
    kill_env
}

@test "[TEST] load_config_file with a given root .editorconfig file in the CWD returns the expected values" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 0 0 "real_readable" "/spfmt.env" || true)
EOF
    ns_exec "cat > '$location/.editorconfig' <<'EOF'
[awk]
root = true
indent_size = 2
indent_char = space
EOF"

    expected="2:space"
    output="$(ns_exec "cd $location; echo "\n" | awk -f /spfmt/src/$script -f /spfmt/src/$depend1 -f /spfmt/src/$depend2 -f /spfmt/tests/modules/editorconfig/harnesses/$harness")"

    [ "${output}" == "${expected}" ]
}

@test "[TEST] load_config_file with a given root .editorconfig file in the directory below returns the expected values" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 1 0 "real_readable" "/spfmt.env" || true)
EOF
    ns_exec "cat > '$location/.editorconfig' <<'EOF'
[awk]
root = true
indent_size = 2
indent_char = space
EOF"

    expected="2:space"
    output="$(ns_exec "cd $location; echo "\n" | awk -f /spfmt/src/$script -f /spfmt/src/$depend1 -f /spfmt/src/$depend2 -f /spfmt/tests/modules/editorconfig/harnesses/$harness")"

    [ "${output}" == "${expected}" ]
}

@test "[TEST] load_config_file with a given root .editorconfig file in the directory below returns the expected values" {
    IFS=':' read -r location input <<EOF
$(filesystem_setup 1 1 "real_readable" "/spfmt.env" || true)
EOF
    ns_exec "cat > '$location/.editorconfig' <<'EOF'
[awk]
root = true
indent_size = 2
indent_char = space
EOF"

    expected="2:space"
    output="$(ns_exec "cd $location; echo "\n" | awk -f /spfmt/src/$script -f /spfmt/src/$depend1 -f /spfmt/src/$depend2 -f /spfmt/tests/modules/editorconfig/harnesses/$harness")"

    [ "${output}" == "${expected}" ]
}

#============#
# TEST CASES #
#============#

#@test "[TEST] load_config_file with a given root .editorconfig file in the root directory returns the expected values" {
#    trap 'kill_env "$NS_PID"' EXIT INT TERM
#    
#    IFS=':' read -r location input <<EOF
#$(filesystem_setup 0 0 "real_readable" "${base}" || true)
#EOF
#    expected="4:space"
#
#    assert_builder \
#        -f "${script}" \
#        -f "${depend1}" \
#        -f "${depend2}" \
#        -h "${harness}" \
#        -x "${expected}"
#}
#
#@test "[TEST] load_config_file with a given root .editorconfig file in /tmp directory returns the expected values" {
#    expected="2:space"
#
#    assert_builder \
#        -f "${script}" \
#        -f "${depend1}" \
#        -f "${depend2}" \
#        -h "${harness}" \
#        -x "${expected}"
#}
#
#@test "[TEST] load_config_file will aggregate multiple .editorconfig files if the first found config file is not root" {
#    expected="2:tab"
#
#    assert_builder \
#        -f "${script}" \
#        -f "${depend1}" \
#        -f "${depend2}" \
#        -h "${harness}" \
#        -x "${expected}"
#}
#
#@test "[TEST] load_config_file early exits and returns empty string when no path is passed." {
#    expected=":"
#
#    assert_builder \
#        -f "${script}" \
#        -f "${depend1}" \
#        -f "${depend2}" \
#        -h "${harness}" \
#        -x "${expected}"
#}

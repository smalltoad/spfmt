#!/usr/bin/env sh

SPFMT_AWK_PROGRAM=$(cat << 'EOF'
AWK_CODE_PLACEHOLDER
EOF
)

case "$@" in
    -h|--help)
        printf '%s\n' "${SPFMT_AWK_PROGRAM}" | awk -f - /dev/null -h
        ;;
    *)
        run_spfmt "$@"
        ;;
esac

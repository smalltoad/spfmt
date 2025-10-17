#!/bin/bash

add_trap() {
    TRAP_COMMAND="$1"
}

command_check() {
    return "$MOCK_COMMAND"
}

# File: project_env.mk
# Desc: Environment configuration for spfmt project
# Author: Joseph Mowery <mowery.joseph@outlook.com>

# Versions
BATS_VERSION := 1.10.0
AWK_VERSION := GNU Awk 5.2.1, API 3.2, PMA Avon 8-g1

# Determine absolute project root dynamically
ENV_MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PROJ_ROOT := $(patsubst %/,%,$(ENV_MK_DIR))

# Project paths
SRC_DIR := $(PROJ_ROOT)/src
TEST_DIR := $(PROJ_ROOT)/tests
BATS_HELPERS := $(TEST_DIR)/bats_helpers
BUILD_DIR := $(PROJ_ROOT)/build

# Install Paths
PREFIX := /usr/local
BINDIR := $(PREFIX)/bin
INSTALL_TARGET := $(BINDIR)/$(PROGRAM_NAME)

# Configuration flags
INFO := 1

# TODO: Using too many cores/introducing parellelism  fails file based BATs test.
JOBS ?= $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)

# CLI options
BATS_OPTIONS := --tap --jobs $(JOBS) --formatter /mnt/c/Development/Workspace/shellspec-format/tests/bats_tap_formatter.sh
AWK_OPTIONS :=

export PROJ_ROOT
export SRC_DIR
export TEST_DIR
export BATS_HELPERS
export BUILD_DIR
export PREFIX
export BINDIR
export INSTALL_TARGET
export INFO
export DEBUG
export VERBOSE
export BATS_OPTIONS
export AWK_OPTIONS

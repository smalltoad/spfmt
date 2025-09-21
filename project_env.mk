#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
# Author: Joseph Mowery <mowery.joseph.git@outlook.com>
# Description: Environment configuration for spfmt project.
# File: project_env.mk
# License: GNU GPLv3

# Versions of dependencies, hand entered at time of development.
BATS_VERSION := Bats 1.10.0
BASH_VERSION := GNU bash, version 5.2.21(1)-release
AWK_VERSION := GNU Awk 5.2.1, API 3.2, PMA Avon 8-g1

# Determine absolute project root dynamically.
ENV_MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PROJ_ROOT := $(patsubst %/,%,$(ENV_MK_DIR))

# Project paths.
SRC_DIR := $(PROJ_ROOT)/src
TEST_DIR := $(PROJ_ROOT)/tests
BATS_HELPERS := $(TEST_DIR)/bats_helpers
BATS_TEST_FORMATTER := $(TEST_DIR)/bats_tap_formatter.sh
BUILD_DIR := $(PROJ_ROOT)/build

# Install Paths
PREFIX := /usr/local
BINDIR := $(PREFIX)/bin
INSTALL_TARGET := $(BINDIR)/$(PROGRAM_NAME)

# Configuration flags.
INFO := 1

JOBS ?= $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)

# CLI options.
BATS_OPTIONS := --tap --jobs $(JOBS) --formatter $(BATS_TEST_FORMATTER)
AWK_OPTIONS :=

# Variables must be exported to be picked up in the Makefile.
export PROJ_ROOT
export SRC_DIR
export TEST_DIR
export BATS_HELPERS
export BUILD_DIR
export PREFIX
export BINDIR
export INSTALL_TARGET
export INFO
export VERBOSE
export BATS_OPTIONS
export AWK_OPTIONS

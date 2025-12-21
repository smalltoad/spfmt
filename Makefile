#  ___  __ _____   ____| | | |_ ___   ____  __| |
# / __||  _   _ \ / _  | | | __/ _ \ / _  |/ _  |
# \__ \| | | | | | (_| | | | || (_) | (_| | (_| |
# |___/|_| |_| |_|\__ _|_|_|\__\___/ \___ |\____|
#
#/**
# [DESCRIPTION]
# Build and installation automation for spfmt (ShellSpec Formatter).
#
# [FILE] Makefile
# [LICENSE] GNU GPLv3
# */

# Includes env file which exports configuration variables. Resides at proj root.
-include env.mk

.PHONY: all build clean install prints-sources print-version test-futs test-build

SHELL := /bin/sh

# Project version-ation.
PROGRAM_NAME := spfmt
VERSION := $(shell cat VERSION 2>/dev/null || $(PRINTF) "VERSION\ file\ not\ found?\n")

#/**
# Source files in dependency order.
#
# Note that manual inclusions/updates here are preferred over including
# everything in the /src folder in order to enforce dependency order and exclude
# non-AWK modules.
# */
SOURCES := spfmt.awk parse.awk editorconfig.awk file_utils.awk
PREPARED_SOURCES = $(addprefix $(SRC_DIR)/, $(SOURCES))
WRAPPER := ./src/cli_wrapper.sh# Hard coded wrapper.

# Output files.
COMBINED_AWK := $(BUILD_DIR)/combined.awk# Concat of all .awk src files.
DISTRIBUTABLE := $(BUILD_DIR)/$(PROGRAM_NAME)# CLI wrapped combined.awk executable.

# Commands.
BATS := $(shell command -v bats 2>/dev/null || echo "bats")
COPY := cp
MKDIR_P := mkdir -p
PRINTF := printf
ECHO := echo
INSTALL := install
CHMOD := chmod
RM := rm -f
RM_RF := rm -rf

# Create build directory if it doesn't exist
$(BUILD_DIR):
	@$(MKDIR_P) "$(BUILD_DIR)" || $(PRINTF) "Could not create build directory.\n"

#/**
# Builds the final AWK file via concatenation.
# This does NOT yet have the CLI wrapper.
# This build artifact is used for build tests.
# */
build: $(DISTRIBUTABLE)

$(COMBINED_AWK): $(PREPARED_SOURCES) $(WRAPPER) | $(BUILD_DIR)
	@$(PRINTF) "=== Building Combined AWK executable ===\n"
	@trap 'rm -f "$$tmp"' EXIT TERM; \
	tmp=$$(mktemp "$@.XXXXXX"); \
	chmod +x "$$tmp"; \
	\
	$(PRINTF) '%s\n' '#!/usr/bin/awk -f' > "$$tmp"; \
	$(PRINTF) '\n' >> "$$tmp"; \
	$(PRINTF) '# %s v%s - Build generated from source files\n' "$(PROGRAM_NAME)" "$(VERSION)" >> "$$tmp"; \
	\
	for src in $(PREPARED_SOURCES); do \
		$(PRINTF) 'Embedding %s\n' "$$(basename "$$src")"; \
	    $(PRINTF) '# Including source file %s\n' "$$(basename "$$src")" >> "$$tmp"; \
	    sed '/^[ \t]*#/d' "$$src" >> "$$tmp"; \
	    $(PRINTF) '\n' >> "$$tmp"; \
	done; \
	\
	mv "$$tmp" "$@"; \
	echo "Build generated and placed at $@"; \

# Build the final distributable via embedding the combined AWK file in a here-doc.
$(DISTRIBUTABLE): $(COMBINED_AWK) | $(BUILD_DIR)
	@$(PRINTF) "=== Embedding Combined AWK executable ===\n"
	@$(COPY) ./src/cli_wrapper.sh $(DISTRIBUTABLE)
	@sed '/AWK_CODE_PLACEHOLDER/r $(COMBINED_AWK)' $(DISTRIBUTABLE) | \
	sed '/AWK_CODE_PLACEHOLDER/d' > $(DISTRIBUTABLE).tmp
	@mv $(DISTRIBUTABLE).tmp $(DISTRIBUTABLE)
	@chmod +x $(DISTRIBUTABLE)

# Clean build artifacts.
clean:
	@$(ECHO) "=== Cleaning Build Directory ==="
	rm -rf $(BUILD_DIR)

# Install to system (optional)
install: $(DISTRIBUTABLE)
	install -m 755 $(DISTRIBUTABLE) /usr/local/bin/$(PROGRAM_NAME)

# Debugging target to show what environment will be passed
print-env:
	@$(ECHO) "=== Environment Configuration ==="
	@$(ECHO) "Project: $(PROGRAM_NAME) v$(VERSION)"
	@$(ECHO) ""
	@$(ECHO) "Versions"
	@$(ECHO) "    AWK: $(AWK_VERSION)"
	@$(ECHO) "    BATS: $(BATS_VERSION)"
	@$(ECHO) "    BASH: $(BASH_VERSION)"
	@$(ECHO) ""
	@$(ECHO) "Build Paths:"
	@$(ECHO) "    PROJ_ROOT: $(PROJ_ROOT)"
	@$(ECHO) "    SRC_DIR: $(SRC_DIR)"
	@$(ECHO) "    TEST_DIR: $(TEST_DIR)"
	@$(ECHO) "    BATS_HELPERS: $(BATS_HELPERS_DIR)"
	@$(ECHO) "    BUILD_DIR: $(BUILD_DIR)"
	@$(ECHO) "    DISTRIBUTABLE: $(DISTRIBUTABLE)"
	@$(ECHO) ""
	@$(ECHO) "Install Paths:"
	@$(ECHO) "    PREFIX: $(PREFIX)"
	@$(ECHO) "    BINDIR: $(BINDIR)"
	@$(ECHO) "    INSTALL_TARGET: $(INSTALL_TARGET)"
	@$(ECHO) ""
	@$(ECHO) "Flags:"
	@$(ECHO) "    INFO: $(INFO)"
	@$(ECHO) ""
	@$(ECHO) "Options:"
	@$(ECHO) "    BATS_OPTIONS: $(BATS_OPTIONS)"
	@$(ECHO) "    AWK_OPTIONS: $(AWK_OPTIONS)"
	@$(ECHO) ""

# Print what files would be included in final distributable via a make install.
print-sources:
	@$(ECHO) "=== Registered Source Files ==="
	@for src in $(PREPARED_SOURCES); do \
		echo "$$src"; done

print-version:
	@$(PRINTF) "%s\n" $(VERSION)

#/**
# Runs all BATS tests within each tests/modules/*/fut.
# These FUTS are mocked functions. Run make test-build for integration tests.
#
# NOTE that other parameters can be passed at the commandline!
#    Example: $ make test INFO=1
# */
test-futs:
	@$(ECHO) "Running tests with configuration:"
	@$(ECHO) "    Project Root: $(PROJ_ROOT)"
	@$(ECHO) "    Test Targets: $(FUTS)"
	@$(ECHO) "    INFO level: $(INFO)"
	@$(ECHO) ""
	@$(ECHO) "Command used:"
	$(BATS) $(BATS_OPTIONS) $(FUTS)

test-build:
	@$(ECHO) "Running tests with configuration:"
	@$(ECHO) "    Project Root: $(PROJ_ROOT)"
	@$(ECHO) "    Test Directory: $(TEST_DIR)"
	@$(ECHO) "    INFO level: $(INFO)"
	@$(ECHO) ""
	@$(ECHO) "Command used:"
	$(BATS) $(BATS_OPTIONS) $(BUILD)

# Default make target
all: clean $(DISTRIBUTABLE)

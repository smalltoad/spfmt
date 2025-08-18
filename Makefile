# File: Makefile
# Desc: Build and installation automation for spfmt (ShellSpec Formatter).
# Author: Joseph Mowery <mowery.joseph@outlook.com>

# Includes env file which exports configuration variables.
-include project_env.mk

.PHONY: all clean install dist dev show-sources

SHELL := /bin/sh

# Project configuration.
PROGRAM_NAME := spfmt
VERSION := 0.1.0

# Source files in dependency order.
SOURCES := spfmt.awk parse.awk editorconfig.awk
PREPARED_SOURCES = $(addprefix $(SRC_DIR)/, $(SOURCES))

# Output files.
COMBINED_AWK := $(BUILD_DIR)/combined.awk
OUTPUT := $(BUILD_DIR)/$(PROGRAM_NAME)
DIST_OUTPUT := $(PROGRAM_NAME)

# Commands.
BATS = $(shell command -v bats 2>/dev/null || echo "bats")
COPY = cp
MKDIR_P = mkdir -p
PRINTF = printf
INSTALL := install
CHMOD := chmod
RM := rm -f
RM_RF := rm -rf

# Create build directory if it doesn't exist
$(BUILD_DIR):
	@$(MKDIR_P) "$(BUILD_DIR)" || $(PRINTF) "Could not create build directory.\n"

$(COMBINED_AWK): $(PREPARED_SOURCES) | $(BUILD_DIR)
	@$(PRINTF) "=== Building Combined AWK executable ===\n"

	@# Shebang for awk
	@echo '#!/usr/bin/awk -f' >> $(COMBINED_AWK)
	@echo '' >> $(COMBINED_AWK)

	@# Autogen header for awk file
	@echo '# $(PROGRAM_NAME) v$(VERSION) - Generated build' >> $(COMBINED_AWK)
	@echo '# Build date: $(shell date)' >> $(COMBINED_AWK)
	@echo '' >> $(COMBINED_AWK)

	@# Concatenate all source files, removing shebangs and comments
	@# sed command 1: Remove lines that start with # (comment-only lines)
	@# sed command 2: For lines void of quotes, remove everything after #
	@# sed command 3: For lines with quotes, preserve quoted strings but remove trailing comments
	@for src in $(PREPARED_SOURCES); do \
		echo "Including source file $$src"; \
		echo "# === START OF $$src === #" >> $(COMBINED_AWK); \
		#sed '/^[ \t]*#/d' "$$src" | \
		#sed '/\"/!s/#.*//' | \
		#sed 's/\(.*\"[^\"]*\"[^\"]*\)#.*/\1/' >> $(COMBINED_AWK); \
		cat $$src >> $(COMBINED_AWK); \
		echo '' >> $(COMBINED_AWK); \
		echo "# === END OF $$src === #" >> $(COMBINED_AWK); \
		echo '' >> $(COMBINED_AWK); \
	done

	@# Make the build file executable
	@chmod +x $(COMBINED_AWK)
	@echo "Build complete: $(COMBINED_AWK)"

# Build the final distributable via embedding the combined AWK file in a here-doc.
$(OUTPUT): $(COMBINED_AWK) | $(BUILD_DIR)
	@$(PRINTF) "=== Embedding Combined AWK executable ===\n"
	@$(COPY) ./src/cli_wrapper.sh $(OUTPUT)
	@sed '/AWK_CODE_PLACEHOLDER/r $(COMBINED_AWK)' $(OUTPUT) | \
	sed '/AWK_CODE_PLACEHOLDER/d' > $(OUTPUT).tmp
	@mv $(OUTPUT).tmp $(OUTPUT)
	@chmod +x $(OUTPUT)

# Clean build artifacts.
clean:
	@echo "=== Cleaning Build Directory ==="
	rm -rf $(BUILD_DIR)
	rm -f $(DIST_OUTPUT)

# Install to system (optional)
install: $(OUTPUT)
	install -m 755 $(OUTPUT) /usr/local/bin/$(PROGRAM_NAME)

# Debugging target to show what environment will be passed
show-env:
	@echo "=== Environment Configuration ==="
	@echo "Project: $(PROGRAM_NAME) v$(VERSION)"
	@echo ""
	@echo "Versioning"
	@echo "    AWK: $(AWK_VERSION)"
	@echo "    BATS: $(BATS_VERSION)"
	@echo "    BASH: $(BASH_VERSION)"
	@echo ""
	@echo "Build Paths:"
	@echo "    PROJ_ROOT: $(PROJ_ROOT)"
	@echo "    SRC_DIR: $(SRC_DIR)"
	@echo "    BUILD_DIR: $(BUILD_DIR)"
	@echo "    OUTPUT: $(OUTPUT)"
	@echo "    TEST_DIR: $(TEST_DIR)"
	@echo "    BATS_HELPERS: $(BATS_HELPERS)"
	@echo ""
	@echo "Install Paths:"
	@echo "    PREFIX: $(PREFIX)"
	@echo "    BINDIR: $(BINDIR)"
	@echo "    INSTALL_TARGET: $(INSTALL_TARGET)"
	@echo ""
	@echo "Flags:"
	@echo "    INFO: $(INFO)"
	@echo ""
	@echo "Options:"
	@echo "    BATS_OPTIONS: $(BATS_OPTIONS)"
	@echo "    AWK_OPTIONS: $(AWK_OPTIONS)"
	@echo ""

# Print what files would be included in final distributable.
show-sources:
	@echo "=== REGISTERED SOURCE FILES ==="
	@for src in $(PREPARED_SOURCES); do echo "    $$src"; done

#/**
# * Runs all tests in the /tests folder
# * To run an individual test file:
# *     ./tests/parse/fut/strip_trailing_whitespace_test.bats
# * To run an individual test file with INFO turned on:
# *     INFO=1 ./tests/parse/fut/strip_trailing_whitespace_test.bats
# */
test:
	@echo "Running tests with configuration:"
	@echo "    Project Root: $(PROJ_ROOT)"
	@echo "    Test Directory: $(TEST_DIR)"
	@echo "    INFO level: $(INFO)"
	@echo "    DEBUG level: $(DEBUG)"
	@echo ""
	@echo "Command used:"
	$(BATS) $(BATS_OPTIONS) $(TEST_DIR)/*/fut/*.bats

# Default make target
all: clean $(OUTPUT)

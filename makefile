.PHONY: all clean build run help install

# Compiler and flags
CC = clang
OBJC = clang
CFLAGS = -Wall -Wextra -O2 -fPIC -std=c11
OBJCFLAGS = $(CFLAGS)
LDFLAGS = -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore \
          -framework CoreGraphics -framework CoreText -framework Foundation \
          -framework AppKit -framework CoreFoundation

# Directories
SRC_DIR = src
INC_DIR = $(SRC_DIR)/inc
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
OBJ_DIR = $(BUILD_DIR)/obj

# Source files
SOURCES = \
    $(SRC_DIR)/main.m \
    $(INC_DIR)/window.m \
    $(INC_DIR)/render.m \
    $(INC_DIR)/shell.m \
    $(INC_DIR)/input.m \
    $(INC_DIR)/terminal.m \
    $(INC_DIR)/clipboard.m \
    $(INC_DIR)/scrollback.m \
    $(INC_DIR)/themes.m \
    $(INC_DIR)/tabs.m \
    $(INC_DIR)/search.m \
    $(INC_DIR)/sessions.m \
    $(INC_DIR)/panes.m \
    $(INC_DIR)/text_renderer.m \
    $(INC_DIR)/url_detector.m \
    $(INC_DIR)/image_renderer.m \
    $(INC_DIR)/profiler.m \
    $(INC_DIR)/shell_integration.m \
    $(INC_DIR)/scripting.m

# Object files
OBJECTS = $(patsubst $(SRC_DIR)/%.m,$(OBJ_DIR)/%.o,$(SOURCES))
OBJECTS := $(patsubst $(INC_DIR)/%.m,$(OBJ_DIR)/%.o,$(OBJECTS))

# Target executable
TARGET = $(BIN_DIR)/mTerm

# Default target
all: build

# Help target
help:
	@echo "mTerm Build System"
	@echo "=================="
	@echo ""
	@echo "Available targets:"
	@echo "  make build      - Build mTerm executable (default)"
	@echo "  make run        - Build and run mTerm"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make install    - Install mTerm to /usr/local/bin"
	@echo "  make cmake      - Configure and build using CMake"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Alternatively, use CMake:"
	@echo "  mkdir build && cd build"
	@echo "  cmake .."
	@echo "  make"

# Build target
build: $(TARGET)
	@echo "✓ Build complete: $(TARGET)"

# Link target
$(TARGET): $(OBJECTS) | $(BIN_DIR)
	@echo "Linking $(TARGET)..."
	$(OBJC) $(OBJCFLAGS) -o $@ $^ $(LDFLAGS)

# Compile Objective-C files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.m | $(OBJ_DIR)
	@echo "Compiling $<..."
	@mkdir -p $(dir $@)
	$(OBJC) $(OBJCFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o: $(INC_DIR)/%.m | $(OBJ_DIR)
	@echo "Compiling $<..."
	@mkdir -p $(dir $@)
	$(OBJC) $(OBJCFLAGS) -c -o $@ $<

# Create directories
$(OBJ_DIR):
	mkdir -p $@
	mkdir -p $@/inc

$(BIN_DIR):
	mkdir -p $@

# Run target
run: build
	@echo "Running mTerm..."
	@$(TARGET)

# Install target
install: build
	@echo "Installing mTerm to /usr/local/bin..."
	@sudo cp $(TARGET) /usr/local/bin/mTerm
	@echo "✓ Installation complete"

# CMake build target
cmake: clean
	@echo "Building with CMake..."
	mkdir -p build
	cd build && cmake .. && make
	@echo "✓ CMake build complete: ./build/bin/mTerm"

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

# Verbose build for debugging
verbose: OBJCFLAGS += -v
verbose: build

# Print variables (for debugging)
print-%:
	@echo $* = $($*)

# Assembler
ASM := fasm
ASM_FLAGS :=

# Change this number when loading more sectors for stage 2
STAGE2_ALLOWED_SECTORS := 2
# Must always be 1
STAGE1_ALLOWED_SECTORS := 1
# max size = number of sectors * 512
STAGE2_MAX_SIZE := $(shell echo $$(($(STAGE2_ALLOWED_SECTORS)*512)))
# Always 512 (one sector)
STAGE1_MAX_SIZE := 512

# Sources
STAGE1_DIR := boot/stage1
STAGE2_DIR := boot/stage2
STAGE1_SOURCES := $(shell find $(STAGE1_DIR) -name "*.asm") \
				  $(shell find $(STAGE1_DIR) -name "*.inc")
STAGE2_SOURCES := $(shell find $(STAGE2_DIR) -name "*.asm") \
				  $(shell find $(STAGE2_DIR) -name "*.inc")
# Binaries
BUILD_DIR := build
STAGE1_BIN := $(BUILD_DIR)/stage1.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin
BOOTLOADER_BIN := $(BUILD_DIR)/bootloader.bin

# Defining static routines
.PHONY: all clean run stage1 stage2 bootloader

# Assemble the bootloader
all: $(BOOTLOADER_BIN)

# Run qemu after building
run: all
	qemu-system-i386 -drive file=$(BOOTLOADER_BIN),format=raw

# Binary removal
clean:
	rm -f $(BOOTLOADER_BIN) $(STAGE1_BIN) $(STAGE2_BIN)

# Combine stage 1 and 2
bootloader: $(BOOTLOADER_BIN)
$(BOOTLOADER_BIN): $(STAGE1_BIN) $(STAGE2_BIN)
	echo "Assembling bootloader.bin"
	@cp $(STAGE1_BIN) $(BOOTLOADER_BIN)
	@cat $(STAGE2_BIN) >> $(BOOTLOADER_BIN)

# Assembling stage 1
stage1: $(STAGE1_BIN)
$(STAGE1_BIN): $(STAGE1_SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) $(STAGE1_DIR)/stage1.asm $@
	# Check binary file size
	@test $$(wc -c < $(STAGE1_BIN)) -eq $(STAGE1_MAX_SIZE) || { echo "Error: $(STAGE1_BIN) size mismatch!"; rm $(STAGE1_BIN); exit 1; }

# Assembling stage 2
stage2: $(STAGE2_BIN)
$(STAGE2_BIN): $(STAGE2_SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) $(STAGE2_DIR)/stage2.asm $@
	# Check binary file size
	@test $$(wc -c < $(STAGE2_BIN)) -eq $(STAGE2_MAX_SIZE) || { echo "Error: $(STAGE2_BIN) size mismatch!"; rm $(STAGE2_BIN); exit 1; }

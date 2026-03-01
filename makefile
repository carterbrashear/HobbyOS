ASM := fasm
ASM_FLAGS :=

STAGE1_DIR := boot/stage1
STAGE2_DIR := boot/stage2
STAGE1_SOURCES := $(shell find $(STAGE1_DIR) -name "*.asm") \
				  $(shell find $(STAGE1_DIR) -name "*.inc")
STAGE2_SOURCES := $(shell find $(STAGE2_DIR) -name "*.asm") \
				  $(shell find $(STAGE2_DIR) -name "*.inc")

BUILD_DIR := build
STAGE1_BIN := $(BUILD_DIR)/stage1.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin
BOOTLOADER_BIN := $(BUILD_DIR)/bootloader.bin

.PHONY: all clean run stage1 stage2 bootloader

all: $(BOOTLOADER_BIN)

run: all
	qemu-system-i386 -drive file=$(BOOTLOADER_BIN),format=raw

clean:
	rm -f $(BOOTLOADER_BIN) $(STAGE1_BIN) $(STAGE2_BIN)

bootloader: $(BOOTLOADER_BIN)
$(BOOTLOADER_BIN): $(STAGE1_BIN) $(STAGE2_BIN)
	echo "Assembling bootloader.bin"
	@cp $(STAGE1_BIN) $(BOOTLOADER_BIN)
	@cat $(STAGE2_BIN) >> $(BOOTLOADER_BIN)

stage1: $(STAGE1_BIN)
$(STAGE1_BIN): $(STAGE1_SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) $(STAGE1_DIR)/stage1.asm $@

stage2: $(STAGE2_BIN)
$(STAGE2_BIN): $(STAGE2_SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) $(STAGE2_DIR)/stage2.asm $@

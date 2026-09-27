.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
CROSS ?= arm-none-eabi-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
PYTHON ?= python3
BUILD ?= build
PICOTOOL ?= firmware/picotool$(if $(filter Windows_NT,$(OS)),.exe,)
CPUFLAGS := -mcpu=cortex-m0plus -mthumb
LINKFLAGS := $(CPUFLAGS) -nostdlib -Wl,--build-id=none
OBJS := $(BUILD)/my_boot2_padded.o $(BUILD)/vector_table_BMA04.o $(BUILD)/assembly.o
.PHONY: all firmware bootloader gentoo gentoo-bootloader gentoo-firmware clean gentoo-clean inspect check
all firmware gentoo gentoo-firmware: $(BUILD)/final.uf2
bootloader gentoo-bootloader: $(BUILD)/my_boot2_padded.S
$(BUILD):
	mkdir -p "$@"
$(BUILD)/my_boot2.o: bootloader/official_preprocessed_boot2.S makefile | $(BUILD)
	$(CC) $(CPUFLAGS) -c $< -o $@
$(BUILD)/my_boot2.elf: $(BUILD)/my_boot2.o bootloader/boot_stage2.ld makefile
	$(CC) $(LINKFLAGS) -T bootloader/boot_stage2.ld $< -o $@
$(BUILD)/my_boot2.bin: $(BUILD)/my_boot2.elf
	$(OBJCOPY) -O binary $< $@
$(BUILD)/my_boot2_padded.S: $(BUILD)/my_boot2.bin bootloader/pad_checksum.py makefile
	$(PYTHON) bootloader/pad_checksum.py -s 0xffffffff $< $@
$(BUILD)/my_boot2_padded.o: $(BUILD)/my_boot2_padded.S makefile
	$(CC) $(CPUFLAGS) -c $< -o $@
$(BUILD)/vector_table_BMA04.o: firmware/vector_table_BMA04.S makefile | $(BUILD)
	$(CC) $(CPUFLAGS) -c $< -o $@
$(BUILD)/assembly.o: firmware/assembly.s makefile | $(BUILD)
	$(CC) $(CPUFLAGS) -c $< -o $@
$(BUILD)/final.elf: $(OBJS) firmware/BMA04_ls.ld makefile
	$(CC) $(LINKFLAGS) -T firmware/BMA04_ls.ld -Wl,-Map=$(BUILD)/final.map $(OBJS) -o $@
$(BUILD)/final.bin: $(BUILD)/final.elf
	$(OBJCOPY) -O binary $< $@
$(BUILD)/validated: $(BUILD)/final.bin validate_firmware.py
	$(PYTHON) validate_firmware.py $<
	touch $@
$(BUILD)/final.uf2: $(BUILD)/final.elf $(BUILD)/validated $(PICOTOOL)
	"$(PICOTOOL)" uf2 convert $< $@
check: $(BUILD)/final.bin
	$(PYTHON) validate_firmware.py $<
inspect: check
	$(OBJDUMP) -h -d $(BUILD)/final.elf
# Remove known generated files only.
clean gentoo-clean:
	$(RM) $(OBJS) $(BUILD)/my_boot2.o $(BUILD)/my_boot2.elf $(BUILD)/my_boot2.bin $(BUILD)/my_boot2_padded.S $(BUILD)/final.elf $(BUILD)/final.bin $(BUILD)/final.uf2 $(BUILD)/final.map $(BUILD)/validated

# Compatibility entry point; shared rules live in the project root.
.DEFAULT_GOAL := all
.PHONY: all clean inspect check
all:
	$(MAKE) -C .. bootloader
clean inspect check:
	$(MAKE) -C .. $@

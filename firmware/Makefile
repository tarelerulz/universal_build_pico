# Compatibility entry point; shared rules live in the project root.
.DEFAULT_GOAL := all
.PHONY: all clean inspect check
all:
	$(MAKE) -C .. all
clean inspect check:
	$(MAKE) -C .. $@

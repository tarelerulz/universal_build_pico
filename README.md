# Bare-metal Pico build

An assembly blink example for the original RP2040 Raspberry Pi Pico, using
GPIO 25 and a hardware-timer delay. Builds boot stage 2 and the application
without an installed Pico SDK. This is not a Pico W or Pico 2 LED example.

## Build

Install an arm-none-eabi GCC toolchain, GNU Make and Python 3.
See HOW_TO_BUILD.txt for platform setup. From this directory:

```sh
# Once, if firmware/picotool is absent (requires Git, CMake and C++ compiler):
bash build_picotool/build_picotool.sh
make
```

The new firmware is **build/final.uf2**. Hold BOOTSEL while connecting the
Pico, then copy this file to its RPI-RP2 drive. The onboard LED should stay
on for half a second, off for half a second, and repeat. Unplug and reconnect
without BOOTSEL to check that it also starts correctly from a fresh power-up.

The timer lesson is in `setup_timer` in firmware/assembly.s:
start the 12 MHz crystal, wait for stability, select it as the reference
clock, and divide by 12 in the watchdog tick generator. Each timer count
then represents one microsecond. This does not enable watchdog resets.
`wait_us` subtracts the starting count from the current count, so it also
works when the low 32-bit counter wraps. Change `DELAY_US` to 250000 to
try a quarter-second on/off interval, then rebuild with `make`.

All platforms use the same makefile. `make gentoo` and `bash build_all.sh`
remain aliases. `make check` validates the boot2 CRC, stack and vector
addresses; `make inspect` displays the linked instructions.
`make clean` removes known outputs in build/.

Overrides: `make CROSS=arm-none-eabi- PICOTOOL=/path/to/picotool`.
`BUILD=build-other` selects a separate output directory (avoid spaces).
The tool builder pins picotool to commit
`25aa087b2c517b4901874a99536e869d4d27b678` and defaults to two compile jobs;
set `JOBS=1` for lower memory use.

## Source layout

- `firmware/assembly.s`: blink program and reset entry.
- `firmware/vector_table_BMA04.S`: the single vector table; unhandled
  exceptions stop in a default handler for inspection.
- `firmware/BMA04_ls.ld`: flash/RAM layout and link-time assertions.
- `bootloader/official_preprocessed_boot2.S`: SDK-derived boot2 source.
- `bootloader/pad_checksum.py`: boot2 padding/checksum generation.
- `makefile` and `validate_firmware.py`: shared build and image checks.

Other `.S`/`.s`/`.ld` files (the annotated boot2 copies,
`firmware/explainedbootloader.s`, and the older `my_boot2_padded.S`
copies) are kept as reference, not inputs to this build. Build output goes
only to `build/`; use `build/final.uf2`.
Subdirectory makefiles forward to the shared root rules.

## Verification and limits

The September 2026 startup/build fixes were compiled and inspected on the
Gentoo Pi 400. Run `make && python3 -m unittest test_validation.py` for
image validation regression checks. Reset now has its Thumb bit set, and all exception vectors
target a real handler. CRC and vector validation runs before UF2 conversion.
This does not replace a hardware boot test: explicit crystal/reference/tick
setup has now been added and compiled, and the UF2 payload checked against
the binary, but the updated image has not yet been tested on hardware.
The startup is an assembly example, not a general C runtime (it does not
copy .data or clear .bss).

See LICENSE and THIRD_PARTY_LICENSES.txt for original and derived work.

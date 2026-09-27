// ----------------------------------------------------------------------------
// This file is a derivative work of the RP2040 second stage boot code from
// the Raspberry Pi Pico SDK (src/rp2040/boot_stage2/boot2_w25q080.S):
//
// Copyright (c) 2019-2021 Raspberry Pi (Trading) Ltd.
// SPDX-License-Identifier: BSD-3-Clause
//
// See THIRD_PARTY_LICENSES.txt for the full license text. The annotations
// and reorganization below are original commentary added for learning
// purposes; the underlying instruction sequence is Raspberry Pi's.
// ----------------------------------------------------------------------------

/*
 * boot2_w25q080_annotated.S
 *
 * Combined reference file — explains how the RP2040 boot stage 2 works.
 *
 * HOW TO READ THIS FILE
 * ---------------------
 * Each section starts with a banner comment showing exactly which file in
 * the Pico SDK the code originally came from, including the line number.
 * The SDK expands all of these files together through the C preprocessor
 * before the assembler ever sees them — that preprocessed output is saved
 * in official_preprocessed_boot2.S in this directory.
 *
 * The actual code here is the cleaned, human-readable version from
 * explainedbootloader.s (firmware/explainedbootloader.s), with raw hex
 * values replaced by named constants and local numeric labels replaced
 * by named labels so the intent is clear.
 *
 * WHAT BOOT STAGE 2 DOES (the big picture)
 * -----------------------------------------
 * The RP2040 has 264KB of on-chip SRAM but no on-chip flash. Programs live
 * on an external SPI flash chip (on the Pico: a W25Q080, 1 MB).
 *
 * On power-up the RP2040 ROM:
 *   1. Copies the first 256 bytes of flash into SRAM at 0x20041f00.
 *   2. Verifies the CRC32 of those 256 bytes (that is what pad_checksum.py
 *      adds — without a valid checksum the ROM refuses to run the code).
 *   3. Jumps to that 256-byte block. That block IS this file.
 *
 * This code then:
 *   1. Raises the QSPI pad drive strength for reliable high-speed operation.
 *   2. Enables the flash chip's Quad-SPI mode (QE bit in status register 2).
 *   3. Sends one "dummy" quad-read command to wake the flash into XIP mode.
 *   4. Configures the SSI controller in memory-mapped Execute-In-Place (XIP)
 *      mode so that flash starting at address 0x10000000 can be read
 *      (and executed) as if it were ordinary memory.
 *   5. Hands control to the user's application by pointing the CPU's vector
 *      table at 0x10000100 (flash + 256 bytes, just after this bootloader)
 *      and jumping to its reset handler.
 *
 * After step 4 the rest of your program, which is sitting in flash, is
 * visible at 0x10000000 and the CPU can fetch instructions directly from it.
 */


/* =========================================================================
 * SECTION 1 — MACRO DEFINITIONS
 * SDK source: src/rp2040/pico_platform/include/pico/asm_helper.S
 * Included by boot2_w25q080.S at line 30 via:
 *   #include "pico/asm_helper.S"
 * Visible in preprocessed output at lines 66–111.
 * =========================================================================
 *
 * The SDK defines shorthand assembly macros so function declarations are
 * consistent across all SDK files. We do NOT use the macros here — they
 * are expanded inline so you can see exactly what they produce.
 *
 * The two macros used in this file:
 *
 *   pico_default_asm_setup
 *     expands to:
 *       .syntax unified
 *       .cpu cortex-m0plus
 *       .thumb
 *
 *   regular_func <name>
 *     expands to:
 *       .global <name>
 *       .type   <name>,%function
 *       .thumb_func
 *       <name>:
 *
 * In the preprocessed output you can see the original macro calls at
 * lines 119 and 123, and the expansion is what the assembler actually sees.
 */

/* Expanded from: pico_default_asm_setup  (boot2_w25q080.S line 89) */
.syntax unified
.cpu cortex-m0plus
.thumb


/* =========================================================================
 * SECTION 2 — HARDWARE REGISTER ADDRESSES AND OFFSETS
 * SDK source: src/rp2040/hardware_regs/include/hardware/regs/ssi.h
 *             src/rp2040/hardware_regs/include/hardware/regs/pads_qspi.h
 * Included by boot2_w25q080.S at lines 31–32.
 * Visible in preprocessed output at lines 114–117 (just the #include lines;
 * the headers themselves define the values as hex literals used inline).
 * =========================================================================
 *
 * Rather than scatter magic hex numbers through the code the way the
 * preprocessed output does, we give every constant a name here.
 *
 * BASE ADDRESSES
 * These are fixed by the RP2040 hardware — see the RP2040 datasheet
 * section 2.2 (Address Map).
 */
.equ PADS_QSPI_BASE,      0x40020000   /* QSPI pad control registers        */
.equ SSI_BASE,            0x18000000   /* Synopsys SSI (SPI) controller      */
.equ XIP_BASE,            0x10000000   /* Start of flash in XIP memory map   */
.equ PPB_BASE,            0xe0000000   /* Cortex-M0+ private peripheral bus  */
.equ M0PLUS_VTOR_OFFSET,  0x0000ed08   /* Vector Table Offset Register       */

/*
 * SSI REGISTER OFFSETS  (relative to SSI_BASE = 0x18000000)
 * The SSI is a Synopsys DesignWare DW_apb_ssi v4.01 core.
 * Full register map: RP2040 datasheet section 4.10.
 */
.equ SSI_CTRLR0,     0x00   /* Control register 0 — frame format, data bits */
.equ SSI_CTRLR1,     0x04   /* Control register 1 — number of data frames   */
.equ SSI_SSIENR,     0x08   /* Enable register — 1=enabled, 0=disabled       */
.equ SSI_BAUDR,      0xf0   /* Baud-rate divider (same offset used inline)   */
.equ SSI_SR,         0x28   /* Status register — TFE and BUSY bits           */
.equ SSI_DR0,        0x60   /* Data register (FIFO) — read and write         */
.equ SSI_SPI_CTRLR0, 0xf4   /* SPI-specific control — XIP/dummy config      */

/*
 * PADS_QSPI REGISTER OFFSETS  (relative to PADS_QSPI_BASE = 0x40020000)
 * Each QSPI pin has its own pad control register.
 * RP2040 datasheet section 2.19.6.
 */
.equ PADS_QSPI_GPIO_QSPI_SCLK, 0x04   /* Clock pin pad control  */
.equ PADS_QSPI_GPIO_QSPI_SD0,  0x08   /* Data pin 0 (MOSI)      */
.equ PADS_QSPI_GPIO_QSPI_SD1,  0x0c   /* Data pin 1 (MISO)      */
.equ PADS_QSPI_GPIO_QSPI_SD2,  0x10   /* Data pin 2 (QSPI IO2)  */
.equ PADS_QSPI_GPIO_QSPI_SD3,  0x14   /* Data pin 3 (QSPI IO3)  */


/* =========================================================================
 * SECTION 3 — BOOT STAGE 2 ENTRY POINT
 * SDK source: src/rp2040/boot_stage2/boot2_w25q080.S  line 100
 * Preprocessed output lines 121–203.
 * =========================================================================
 *
 * The ROM jumps here after CRC verification.
 * r3 is used throughout as a base-address register (convention in this file).
 *
 * Expanded from: regular_func _stage2_boot
 */
.section .text
.global _stage2_boot
.type _stage2_boot,%function
.thumb_func
_stage2_boot:
    push {lr}                          /* Save return address from ROM.
                                        * Normally LR is 0 here but the ROM
                                        * can call boot2 with a real return
                                        * address for testing purposes.       */


    /* -------------------------------------------------------------------
     * STEP 1: Configure QSPI pad drive strength.
     *
     * The default drive strength is 4 mA, which causes signal integrity
     * problems at the high clock speeds we will use for XIP. We bump the
     * SCLK pin to 8 mA (drive field = 2) and enable its input buffer.
     * For the data pins we clear the schmitt-trigger enable (bit 1) to
     * reduce capacitive load.
     *
     * Pad control register bits (RP2040 datasheet table 294):
     *   bits [5:4]  DRIVE  — 0=2mA, 1=4mA, 2=8mA, 3=12mA
     *   bit  [0]    SLEWFAST — 1 = fast slew rate
     * So  (2 << 4 | 1) = 0x21 = 8 mA drive + fast slew.
     * ------------------------------------------------------------------- */
    ldr r3, =PADS_QSPI_BASE
    movs r0, #(2 << 4 | 1)                       /* 8 mA drive, fast slew  */
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SCLK]

    /* Read current pad setting for SD0 then clear bit 1 (schmitt trigger).
     * Write the same value to all four data pins so they match.           */
    ldr r0, [r3, #PADS_QSPI_GPIO_QSPI_SD0]
    movs r1, #2                                   /* bit 1 = schmitt enable */
    bics r0, r1                                   /* clear it               */
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD0]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD1]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD2]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD3]


    /* -------------------------------------------------------------------
     * STEP 2: Disable the SSI controller before changing its configuration.
     *
     * The SSI must be disabled (SSIENR = 0) before writing to CTRLR0,
     * CTRLR1, BAUDR, or SPI_CTRLR0. This is a hardware requirement.
     * ------------------------------------------------------------------- */
    ldr r3, =SSI_BASE

    movs r1, #0
    str r1, [r3, #SSI_SSIENR]                    /* disable SSI            */

    /* Set CTRLR1 = 2: receive up to 3 data frames (NDF field = 2 means
     * "receive NDF+1 = 3 frames"). Used for the two-byte status register
     * reads later (command byte + one dummy + one data byte).             */
    movs r1, #2
    str r1, [r3, #SSI_CTRLR1]

    /* Set baud-rate divider to 2 (register value 1 means divide-by-2
     * because the minimum is 2). This gives SPI clock = sys_clk / 2.
     * Offset 0xf0 = SSI_BAUDR.                                           */
    movs r1, #1
    movs r2, #0xf0
    str r1, [r3, r2]                              /* BAUDR = 1 (÷2)        */


/* =========================================================================
 * SECTION 4 — ENABLE QUAD MODE IN THE FLASH CHIP
 * SDK source: src/rp2040/boot_stage2/boot2_w25q080.S  line 165
 * Preprocessed output lines 165–216.
 * =========================================================================
 *
 * The W25Q080 flash chip defaults to standard single-bit SPI after power-up.
 * To use Quad SPI (four data lines simultaneously, 4× the throughput) we
 * must set the QE (Quad Enable) bit in Status Register 2.
 *
 * Protocol for the W25Q080:
 *   Read SR2:   send 0x35, then read one byte back
 *   Write SR:   send 0x06 (write enable), then 0x01 (write SR), SR1, SR2
 *
 * First we put the SSI into standard single-bit SPI mode so we can talk
 * to the flash using regular commands.
 */
program_sregs:
    /* CTRLR0 for standard SPI:
     *   bits [20:16] = 7  → 8-bit data frame (DFS_32 field = 7 means 8 bits)
     *   bits [11:8]  = 0  → EEPROM-style read (transmit then receive)
     * Everything else = 0 (standard Motorola SPI, no loopback, etc.)     */
    ldr r1, =((7 << 16) | (0 << 8))
    str r1, [r3, #SSI_CTRLR0]

    movs r1, #1
    str r1, [r3, #SSI_SSIENR]                    /* enable SSI             */

    /* Read flash Status Register 2 (command 0x35).                       */
    movs r0, #0x35
    bl read_flash_sreg                            /* returns SR2 in r0     */

    /* Check if QE bit (bit 1) is already set. If yes, skip programming.  */
    movs r2, #0x02                                /* QE bit mask           */
    cmp r0, r2
    beq skip_sreg_programming


    /* --- QE bit not set, so we need to program it. --- */

    /* Send Write Enable command (0x06) so the chip will accept a write.  */
    movs r1, #0x06
    str r1, [r3, #SSI_DR0]

    bl wait_ssi_ready
    ldr r1, [r3, #SSI_DR0]                       /* drain RX FIFO          */

    /* Send Write Status Register command:
     *   0x01  = WRSR (write status registers 1 and 2)
     *   0x00  = SR1 value (no block protect, no other flags)
     *   r2    = SR2 value (QE bit = 0x02)                                 */
    movs r1, #0x01
    str r1, [r3, #SSI_DR0]
    movs r0, #0
    str r0, [r3, #SSI_DR0]                       /* SR1 = 0x00             */
    str r2, [r3, #SSI_DR0]                       /* SR2 = 0x02 (QE=1)     */

    bl wait_ssi_ready
    ldr r1, [r3, #SSI_DR0]                       /* drain 3 RX bytes       */
    ldr r1, [r3, #SSI_DR0]
    ldr r1, [r3, #SSI_DR0]


    /* Poll Status Register 1 until the flash finishes the write.
     * WIP (Write In Progress) is bit 0 of SR1. Command 0x05 = RDSR1.    */
wait_flash_write_done:
    movs r0, #0x05
    bl read_flash_sreg
    movs r1, #1
    tst r0, r1                                    /* test WIP bit           */
    bne wait_flash_write_done                     /* loop until WIP = 0     */


skip_sreg_programming:
    /* Disable SSI again before switching to quad mode configuration.     */
    movs r1, #0
    str r1, [r3, #SSI_SSIENR]


/* =========================================================================
 * SECTION 5 — DUMMY QUAD READ (wake the flash into continuous-read mode)
 * SDK source: src/rp2040/boot_stage2/boot2_w25q080.S  line 202
 * Preprocessed output lines 218–252.
 * =========================================================================
 *
 * The W25Q080 has a "continuous read mode" where after the first quad read
 * you can keep clocking data without re-sending the command byte each time.
 * To enter this mode we send one complete quad I/O read command (0xEB),
 * including a special "mode" byte (0xA0) that tells the chip to stay in
 * continuous mode. After this the flash is primed for XIP.
 *
 * This section configures the SSI for quad SPI then sends that one read.
 */
dummy_read:
    /* CTRLR0 for quad SPI receive:
     *   bits [22:21] = 2  → quad mode (SPI_FRF field)
     *   bits [20:16] = 31 → 32-bit data frame (DFS_32)
     *   bits [11:8]  = 3  → EEPROM read mode (both TX and RX)            */
    ldr r1, =((0x2 << 21) | (31 << 16) | (0x3 << 8))
    str r1, [r3, #SSI_CTRLR0]

    /* CTRLR1 = 0: receive exactly 1 data frame.                          */
    movs r1, #0
    str r1, [r3, #SSI_CTRLR1]

    /* SPI_CTRLR0 for the dummy read command:
     *   bits [31:24]  = 0x00  → no "mode continuation" bits yet
     *   bits [17:11]  = 4     → 4 dummy clocks after address
     *   bits [9:8]    = 0x2   → quad address lines
     *   bits [1:0]    = 0x1   → command + address phase (standard)
     *   bits [5:2]    = 8     → address length = 8 bits (×4 = 32 clocks) */
    ldr r1, =((8 << 2) | (4 << 11) | (0x2 << 8) | (0x1 << 0))
    ldr r0, =(SSI_BASE + SSI_SPI_CTRLR0)
    str r1, [r0]

    movs r1, #1
    str r1, [r3, #SSI_SSIENR]                    /* enable SSI             */

    /* Send the quad I/O fast-read command and the mode/continuation byte.
     * 0xEB = Fast Read Quad I/O command (W25Q080 datasheet table 8.2.13)
     * 0xA0 = mode byte: bits [7:4] = 0xA means "stay in continuous mode" */
    movs r1, #0xeb
    str r1, [r3, #SSI_DR0]
    movs r1, #0xa0
    str r1, [r3, #SSI_DR0]

    bl wait_ssi_ready

    /* Disable SSI before reconfiguring for permanent XIP operation.      */
    movs r1, #0
    str r1, [r3, #SSI_SSIENR]


/* =========================================================================
 * SECTION 6 — CONFIGURE SSI FOR PERMANENT MEMORY-MAPPED XIP
 * SDK source: src/rp2040/boot_stage2/boot2_w25q080.S  line 261
 * Preprocessed output lines 258–265.
 * =========================================================================
 *
 * Now we set up the SSI so that reads from the XIP address range
 * (0x10000000 – 0x10FFFFFF) are automatically turned into quad SPI
 * read commands to the flash chip with no CPU involvement.
 *
 * SPI_CTRLR0 for XIP mode:
 *   bits [31:24] = 0xa0  → "mode continuation" byte sent instead of command
 *                          (0xA0 keeps the flash in continuous-read mode so
 *                          the command byte is skipped on every read)
 *   bits [17:11] = 4     → 4 dummy clocks between address and data
 *   bits [9:8]   = 0x0   → standard SPI for command phase
 *   bits [5:2]   = 8     → 8-bit address field (actual address = 24 bits
 *                          because it is sent in quad mode = 8 × 4 lines)
 *   bits [1:0]   = 0x2   → XIP mode (no command byte, address then data)
 */
configure_ssi:
    ldr r1, =((0xa0 << 24) | (8 << 2) | (4 << 11) | (0x0 << 8) | (0x2 << 0))
    ldr r0, =(SSI_BASE + SSI_SPI_CTRLR0)
    str r1, [r0]

    /* Enable SSI. From this point on, any read from 0x10000000+ is
     * transparently served from flash over quad SPI.                     */
    movs r1, #1
    str r1, [r3, #SSI_SSIENR]


/* =========================================================================
 * SECTION 7 — HAND CONTROL TO THE USER APPLICATION
 * SDK source: src/rp2040/boot_stage2/asminclude/boot2_helpers/exit_from_boot2.S
 * Included by boot2_w25q080.S at line 272.
 * Preprocessed output lines 271–290.
 * =========================================================================
 *
 * The bootloader can be called two ways:
 *   1. Normally (LR = 0 when the ROM jumps here): jump into the application.
 *   2. With a real return address (LR != 0, used for ROM testing): return.
 *
 * In the normal case we redirect the CPU to the application's vector table.
 * The application's vector table lives at flash + 0x100 (right after this
 * 256-byte bootloader block). The vector table's first two words are:
 *   word 0: initial stack pointer value
 *   word 1: address of the reset handler (application entry point)
 */
check_return:
    pop {r0}                           /* retrieve saved LR                 */
    cmp r0, #0
    beq vector_into_flash              /* LR was 0: normal boot, go to app  */
    bx r0                              /* LR was nonzero: return to caller   */

vector_into_flash:
    /* Point the CPU's Vector Table Offset Register at the application.
     * VTOR tells the hardware where interrupt/exception vectors live.
     * From now on the application's vectors are used, not the ROM's.     */
    ldr r0, =(XIP_BASE + 0x100)
    ldr r1, =(PPB_BASE + M0PLUS_VTOR_OFFSET)
    str r0, [r1]

    /* Load the application's initial stack pointer (word 0) and
     * reset handler address (word 1) from the application vector table.  */
    ldmia r0, {r0, r1}
    msr msp, r0                        /* set the main stack pointer        */
    bx r1                              /* jump to the application           */


/* =========================================================================
 * SECTION 8 — HELPER: WAIT FOR SSI IDLE
 * SDK source: src/rp2040/boot_stage2/asminclude/boot2_helpers/wait_ssi_ready.S
 * Included by boot2_w25q080.S at line 276.
 * Preprocessed output lines 294–310.
 * =========================================================================
 *
 * Waits until:
 *   1. The transmit FIFO is empty (TFE bit, SR bit 2 = 1), AND
 *   2. The SSI is not busy (BUSY bit, SR bit 0 = 0).
 *
 * Both conditions must be true before it is safe to read received data or
 * change configuration. r3 must already point to SSI_BASE (caller's job).
 */
wait_ssi_ready:
    push {r0, r1, lr}

wait_ssi_ready_loop:
    ldr r1, [r3, #SSI_SR]

    /* Check TFE (Transmit FIFO Empty) — bit 2. Loop while TFE = 0.      */
    movs r0, #4
    tst r1, r0
    beq wait_ssi_ready_loop

    /* Check BUSY — bit 0. Loop while BUSY = 1.                           */
    movs r0, #1
    tst r1, r0
    bne wait_ssi_ready_loop

    pop {r0, r1, pc}


/* =========================================================================
 * SECTION 9 — HELPER: READ FLASH STATUS REGISTER
 * SDK source: src/rp2040/boot_stage2/asminclude/boot2_helpers/read_flash_sreg.S
 * Included by boot2_w25q080.S at line 278.
 * Preprocessed output lines 313–329.
 * =========================================================================
 *
 * Sends a status-register read command to the flash and returns the result.
 *
 * Input:  r0 = command byte (0x05 = RDSR1, 0x35 = RDSR2)
 *         r3 = SSI_BASE  (set by caller, stays valid throughout)
 * Output: r0 = status register value read back from flash
 *
 * The SPI protocol requires sending a dummy byte after the command to
 * clock out the response: we send the command byte twice (the second
 * transmission creates the clock cycles needed to receive the reply).
 * We then discard the first received byte (echoed command) and return
 * the second (the actual status register value).
 */
.global read_flash_sreg
.type read_flash_sreg,%function
.thumb_func
read_flash_sreg:
    push {r1, lr}

    str r0, [r3, #SSI_DR0]           /* send command byte                  */
    str r0, [r3, #SSI_DR0]           /* send dummy byte to clock the reply  */

    bl wait_ssi_ready

    ldr r0, [r3, #SSI_DR0]           /* discard first RX byte (echoed cmd)  */
    ldr r0, [r3, #SSI_DR0]           /* return second RX byte (SR value)    */

    pop {r1, pc}


/* =========================================================================
 * LITERAL POOL
 * SDK source: src/rp2040/boot_stage2/boot2_w25q080.S  (end of file)
 * Preprocessed output lines 333–335.
 * =========================================================================
 *
 * .ltorg forces the assembler to emit all pending literal values (the
 * addresses loaded with ldr r0, =... instructions) here at the end of
 * the file. They must fit within 256 bytes total or the CRC/size check
 * will fail.
 */
.global literals
literals:
.ltorg

.end

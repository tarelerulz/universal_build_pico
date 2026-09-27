/*
 * Cleaned RP2040 boot stage 2 for W25Q080-compatible SPI flash.
 *
 * This is cleaned from the preprocessed SDK output:
 *   - removed #line markers from the C preprocessor
 *   - removed unused macro definitions/includes
 *   - expanded the SDK function macros into plain labels/directives
 *   - kept the actual boot code and helper routines
 *
 * This code is the second-stage bootloader. The RP2040 ROM copies this
 * 256-byte block from external flash into SRAM, runs it, and this code
 * configures the QSPI SSI interface so the rest of flash is memory-mapped
 * at 0x10000000. Then it jumps into the user's real program vector table.
 */

.syntax unified
.cpu cortex-m0plus
.thumb

/* Hardware base addresses */
.equ PADS_QSPI_BASE,      0x40020000
.equ SSI_BASE,            0x18000000
.equ XIP_BASE,            0x10000000
.equ PPB_BASE,            0xe0000000
.equ M0PLUS_VTOR_OFFSET,  0x0000ed08

/* SSI register offsets used here */
.equ SSI_CTRLR0,          0x00
.equ SSI_CTRLR1,          0x04
.equ SSI_SSIENR,          0x08
.equ SSI_SR,              0x28
.equ SSI_DR0,             0x60
.equ SSI_SPI_CTRLR0,      0xf4

/* PADS_QSPI register offsets used here */
.equ PADS_QSPI_GPIO_QSPI_SCLK, 0x04
.equ PADS_QSPI_GPIO_QSPI_SD0,  0x08
.equ PADS_QSPI_GPIO_QSPI_SD1,  0x0c
.equ PADS_QSPI_GPIO_QSPI_SD2,  0x10
.equ PADS_QSPI_GPIO_QSPI_SD3,  0x14

.section .text
.global _stage2_boot
.type _stage2_boot,%function
.thumb_func
_stage2_boot:
    push {lr}

    /* Configure QSPI pad drive strength and input enable. */
    ldr r3, =PADS_QSPI_BASE
    movs r0, #(2 << 4 | 1)
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SCLK]

    ldr r0, [r3, #PADS_QSPI_GPIO_QSPI_SD0]
    movs r1, #2
    bics r0, r1
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD0]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD1]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD2]
    str r0, [r3, #PADS_QSPI_GPIO_QSPI_SD3]

    /* Start configuring the SSI controller. */
    ldr r3, =SSI_BASE

    /* Disable SSI while changing configuration. */
    movs r1, #0
    str r1, [r3, #SSI_SSIENR]

    /* Only one data frame is needed for commands/status reads. */
    movs r1, #2
    str r1, [r3, #SSI_CTRLR1]

    /* Set baud-rate divider. */
    movs r1, #1
    movs r2, #0xf0
    str r1, [r3, r2]

program_sregs:
    /* Standard SPI mode, 8-bit frames, transmit/receive. */
    ldr r1, =((7 << 16) | (0 << 8))
    str r1, [r3, #SSI_CTRLR0]

    /* Enable SSI. */
    movs r1, #1
    str r1, [r3, #SSI_SSIENR]

    /* Read flash status register 2. */
    movs r0, #0x35
    bl read_flash_sreg

    /* If QE bit is already set, skip programming it. */
    movs r2, #0x02
    cmp r0, r2
    beq skip_sreg_programming

    /* Write enable command: 0x06. */
    movs r1, #0x06
    str r1, [r3, #SSI_DR0]

    bl wait_ssi_ready
    ldr r1, [r3, #SSI_DR0]

    /* Write status registers: 0x01, then SR1=0, SR2=QE bit. */
    movs r1, #0x01
    str r1, [r3, #SSI_DR0]
    movs r0, #0
    str r0, [r3, #SSI_DR0]
    str r2, [r3, #SSI_DR0]

    bl wait_ssi_ready
    ldr r1, [r3, #SSI_DR0]
    ldr r1, [r3, #SSI_DR0]
    ldr r1, [r3, #SSI_DR0]

wait_flash_write_done:
    /* Poll flash status register 1 until WIP bit clears. */
    movs r0, #0x05
    bl read_flash_sreg
    movs r1, #1
    tst r0, r1
    bne wait_flash_write_done

skip_sreg_programming:
    /* Disable SSI before switching to XIP/dummy-read configuration. */
    movs r1, #0
    str r1, [r3, #SSI_SSIENR]

dummy_read:
    /* Configure quad fast-read mode for the dummy read. */
    ldr r1, =((0x2 << 21) | (31 << 16) | (0x3 << 8))
    str r1, [r3, #SSI_CTRLR0]

    movs r1, #0
    str r1, [r3, #SSI_CTRLR1]

    ldr r1, =((8 << 2) | (4 << 11) | (0x2 << 8) | (0x1 << 0))
    ldr r0, =(SSI_BASE + SSI_SPI_CTRLR0)
    str r1, [r0]

    movs r1, #1
    str r1, [r3, #SSI_SSIENR]

    /* Send quad I/O read command 0xeb and a dummy address byte. */
    movs r1, #0xeb
    str r1, [r3, #SSI_DR0]
    movs r1, #0xa0
    str r1, [r3, #SSI_DR0]

    bl wait_ssi_ready

    /* Disable SSI again before final memory-mapped XIP setup. */
    movs r1, #0
    str r1, [r3, #SSI_SSIENR]

configure_ssi:
    /* Final XIP read configuration: command 0xeb, 8 dummy clocks, quad address/data. */
    ldr r1, =((0xa0 << 24) | (8 << 2) | (4 << 11) | (0x0 << 8) | (0x2 << 0))
    ldr r0, =(SSI_BASE + SSI_SPI_CTRLR0)
    str r1, [r0]

    /* Enable SSI. From here, flash can be executed from XIP memory. */
    movs r1, #1
    str r1, [r3, #SSI_SSIENR]

check_return:
    /* If called with a nonzero return address, return there. Normally this is zero. */
    pop {r0}
    cmp r0, #0
    beq vector_into_flash
    bx r0

vector_into_flash:
    /* Point vector table to the real application at flash + 0x100. */
    ldr r0, =(XIP_BASE + 0x100)
    ldr r1, =(PPB_BASE + M0PLUS_VTOR_OFFSET)
    str r0, [r1]

    /* Load application's initial stack pointer and reset handler. */
    ldmia r0, {r0, r1}
    msr msp, r0
    bx r1

wait_ssi_ready:
    push {r0, r1, lr}

wait_ssi_ready_loop:
    ldr r1, [r3, #SSI_SR]

    /* Wait until transmit FIFO is empty. */
    movs r0, #4
    tst r1, r0
    beq wait_ssi_ready_loop

    /* Wait until SSI is no longer busy. */
    movs r0, #1
    tst r1, r0
    bne wait_ssi_ready_loop

    pop {r0, r1, pc}

.global read_flash_sreg
.type read_flash_sreg,%function
.thumb_func
read_flash_sreg:
    push {r1, lr}

    /* Send the status-register command twice: command + dummy byte/read slot. */
    str r0, [r3, #SSI_DR0]
    str r0, [r3, #SSI_DR0]

    bl wait_ssi_ready

    /* Discard first received byte; return second byte in r0. */
    ldr r0, [r3, #SSI_DR0]
    ldr r0, [r3, #SSI_DR0]

    pop {r1, pc}

.global literals
literals:
.ltorg

.end

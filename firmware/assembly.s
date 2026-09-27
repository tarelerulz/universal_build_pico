.syntax unified
.cpu cortex-m0plus
.thumb

/* ============================================================
   Raspberry Pi Pico RP2040 bare-metal blink
   Uses hardware timer instead of a countdown loop
   LED = GPIO 25
   ============================================================ */

.equ RESETS_BASE,        0x4000C000
.equ RESETS_RESET,       RESETS_BASE + 0x00
.equ RESETS_RESET_DONE,  RESETS_BASE + 0x08
.equ RESETS_RESET_CLR,   RESETS_BASE + 0x3000
.equ TIMER_RESET_BIT,    1 << 21
.equ GPIO_RESET_BITS,    (1 << 5) | (1 << 8)  /* IO_BANK0 + PADS_BANK0 */

/* Crystal -> reference clock -> watchdog tick -> timer counter. */
.equ XOSC_BASE,          0x40024000
.equ XOSC_CTRL,          XOSC_BASE + 0x00
.equ XOSC_STATUS,        XOSC_BASE + 0x04
.equ XOSC_STARTUP,       XOSC_BASE + 0x0C
.equ XOSC_ENABLE_12MHZ,  (0xFAB << 12) | 0xAA0
.equ XOSC_STABLE,        1 << 31
.equ XOSC_STARTUP_DELAY, 47 /* 47 * 256 crystal cycles, about 1 ms */
.equ CLOCKS_BASE,        0x40008000
.equ CLK_REF_CTRL,       CLOCKS_BASE + 0x30
.equ CLK_REF_DIV,        CLOCKS_BASE + 0x34
.equ CLK_REF_SELECTED,   CLOCKS_BASE + 0x38
.equ CLK_REF_SRC_XOSC,   2
.equ CLK_REF_XOSC_READY, 1 << CLK_REF_SRC_XOSC
.equ CLK_REF_DIV_ONE,    1 << 8
.equ WATCHDOG_TICK,      0x4005802C
.equ TICK_ENABLE,        1 << 9
.equ TICK_RUNNING,       1 << 10
.equ TICK_CYCLES_PER_US, 12

.equ IO_BANK0_BASE,      0x40014000
.equ GPIO25_CTRL,        IO_BANK0_BASE + 0x0CC

.equ PADS_BANK0_BASE,    0x4001C000
.equ GPIO25_PAD,         PADS_BANK0_BASE + 0x68

.equ SIO_BASE,           0xD0000000
.equ GPIO_OE_SET,        SIO_BASE + 0x024
.equ GPIO_OUT_SET,       SIO_BASE + 0x014
.equ GPIO_OUT_CLR,       SIO_BASE + 0x018

.equ TIMER_BASE,         0x40054000
.equ TIMERAWL,           TIMER_BASE + 0x28
.equ TIMER_PAUSE,        TIMER_BASE + 0x30

.equ GPIO25_BIT,         1 << 25
.equ FUNC_SIO,           5
.equ DELAY_US,           500000

/* ============================================================
   Vector table
   ============================================================ */

/* The complete vector table lives in vector_table_BMA04.S. */

/* ============================================================
   Program code
   ============================================================ */

.section .reset, "ax"
.global _entry_point
.global _start

_start:
.thumb_func
_entry_point:
    bl setup_timer
    bl setup_gpio25

main_loop:
    bl led_on

    ldr r0, =DELAY_US
    bl wait_us

    bl led_off

    ldr r0, =DELAY_US
    bl wait_us

    b main_loop

/* ============================================================
   setup_timer
   Make each timer count one microsecond, without the SDK or a PLL.
   Assumes the original Pico's 12 MHz crystal. This starts the tick
   generator inside the watchdog, NOT the watchdog reset countdown.
   ============================================================ */

setup_timer:
    /* Stop ticks while changing their reference clock. */
    ldr r0, =WATCHDOG_TICK
    movs r1, #0
    str r1, [r0]

    /* Allow the crystal to settle before using it as a clock. */
    ldr r0, =XOSC_STARTUP
    movs r1, #XOSC_STARTUP_DELAY
    str r1, [r0]
    ldr r0, =XOSC_CTRL
    ldr r1, =XOSC_ENABLE_12MHZ
    str r1, [r0]
    ldr r0, =XOSC_STATUS
    ldr r2, =XOSC_STABLE
wait_xosc_stable:
    ldr r1, [r0]
    tst r1, r2
    beq wait_xosc_stable

    /* Reference clock = crystal / 1 = 12 MHz.
       SELECTED reports completion of the glitchless clock switch. */
    ldr r0, =CLK_REF_DIV
    ldr r1, =CLK_REF_DIV_ONE
    str r1, [r0]
    ldr r0, =CLK_REF_CTRL
    movs r1, #CLK_REF_SRC_XOSC
    str r1, [r0]
    ldr r0, =CLK_REF_SELECTED
    movs r2, #CLK_REF_XOSC_READY
wait_ref_selected:
    ldr r1, [r0]
    tst r1, r2
    beq wait_ref_selected

    /* Release TIMER explicitly; CLR alias affects only the chosen bit. */
    ldr r0, =RESETS_RESET_CLR
    ldr r2, =TIMER_RESET_BIT
    str r2, [r0]
    ldr r0, =RESETS_RESET_DONE
wait_timer_reset_done:
    ldr r1, [r0]
    tst r1, r2
    beq wait_timer_reset_done
    ldr r0, =TIMER_PAUSE
    movs r1, #0
    str r1, [r0]

    /* 12 reference cycles per tick: 12 MHz / 12 = 1 MHz.
       The counter need not start at zero: wait_us measures a difference. */
    ldr r0, =WATCHDOG_TICK
    ldr r1, =(TICK_ENABLE | TICK_CYCLES_PER_US)
    str r1, [r0]
    ldr r2, =TICK_RUNNING
wait_tick_running:
    ldr r1, [r0]
    tst r1, r2
    beq wait_tick_running
    bx lr

/* ============================================================
   setup_gpio25
   Turns GPIO 25 into a normal SIO output pin
   ============================================================ */

setup_gpio25:
    /* Release both the pin controls and electrical pads from reset. */
    ldr r0, =RESETS_RESET_CLR
    ldr r2, =GPIO_RESET_BITS
    str r2, [r0]

wait_io_reset_done:
    ldr r0, =RESETS_RESET_DONE
    ldr r1, [r0]
    ands r1, r2
    cmp r1, r2
    bne wait_io_reset_done

    /* Set GPIO25 function to SIO */
    ldr r0, =GPIO25_CTRL
    movs r1, #FUNC_SIO
    str r1, [r0]

    /* Enable GPIO25 output */
    ldr r0, =GPIO_OE_SET
    ldr r1, =GPIO25_BIT
    str r1, [r0]

    bx lr

/* ============================================================
   led_on
   ============================================================ */

led_on:
    ldr r0, =GPIO_OUT_SET
    ldr r1, =GPIO25_BIT
    str r1, [r0]
    bx lr

/* ============================================================
   led_off
   ============================================================ */

led_off:
    ldr r0, =GPIO_OUT_CLR
    ldr r1, =GPIO25_BIT
    str r1, [r0]
    bx lr

/* ============================================================
   wait_us
   r0 = number of microseconds to wait

   Uses TIMERAWL, the low 32 bits of the RP2040 timer.
   This version handles wraparound correctly by subtracting.
   ============================================================ */

wait_us:
    ldr r1, =TIMERAWL
    ldr r2, [r1]          /* start time */

wait_loop:
    ldr r3, [r1]          /* current time */
    subs r3, r3, r2       /* elapsed = current - start */
    cmp r3, r0
    blo wait_loop
    bx lr

/* ============================================================
   Stack
   Adjust this if your linker script defines RAM differently.
   RP2040 SRAM normally ends at 0x20042000.
   ============================================================ */

.equ _stack_top, 0x20042000

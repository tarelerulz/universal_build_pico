# This is the C-preprocessor output of boot2_w25q080.S from the Raspberry
# Pi Pico SDK (src/rp2040/boot_stage2/), saved here for reference.
#
# Copyright (c) 2019-2021 Raspberry Pi (Trading) Ltd.
# SPDX-License-Identifier: BSD-3-Clause
#
# See THIRD_PARTY_LICENSES.txt for the full license text.

# 0 "pico-sdk/src/rp2040/boot_stage2/compile_time_choice.S"
# 1 "pico-examples/build/pico-sdk/src/rp2040/boot_stage2//"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "pico-sdk/src/rp2040/boot_stage2/compile_time_choice.S"
# 11 "pico-sdk/src/rp2040/boot_stage2/compile_time_choice.S"
# 1 "pico-sdk/src/rp2040/boot_stage2/include/boot_stage2/config.h" 1 3 4
# 12 "pico-sdk/src/rp2040/boot_stage2/include/boot_stage2/config.h" 3 4
# 1 "pico-sdk/src/common/pico_base_headers/include/pico.h" 1 3 4
# 26 "pico-sdk/src/common/pico_base_headers/include/pico.h" 3 4
# 1 "pico-sdk/src/common/pico_base_headers/include/pico/types.h" 1 3 4
# 27 "pico-sdk/src/common/pico_base_headers/include/pico.h" 2 3 4
# 1 "pico-examples/build/generated/pico_base/pico/version.h" 1 3 4
# 28 "pico-sdk/src/common/pico_base_headers/include/pico.h" 2 3 4
# 62 "pico-sdk/src/common/pico_base_headers/include/pico.h" 3 4
# 1 "pico-sdk/src/common/pico_base_headers/include/pico/config.h" 1 3 4
# 19 "pico-sdk/src/common/pico_base_headers/include/pico/config.h" 3 4
# 1 "pico-examples/build/generated/pico_base/pico/config_autogen.h" 1 3 4






# 1 "pico-sdk/src/boards/include/boards/pico.h" 1 3 4
# 17 "pico-sdk/src/boards/include/boards/pico.h" 3 4

# 75 "pico-sdk/src/boards/include/boards/pico.h" 3 4

# 8 "pico-examples/build/generated/pico_base/pico/config_autogen.h" 2 3 4
# 1 "pico-sdk/src/rp2_common/cmsis/include/cmsis/rename_exceptions.h" 1 3 4
# 9 "pico-examples/build/generated/pico_base/pico/config_autogen.h" 2 3 4
# 20 "pico-sdk/src/common/pico_base_headers/include/pico/config.h" 2 3 4
# 63 "pico-sdk/src/common/pico_base_headers/include/pico.h" 2 3 4

# 1 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 1 3 4
# 23 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 3 4
# 1 "pico-sdk/src/rp2_common/pico_platform_compiler/include/pico/platform/compiler.h" 1 3 4
# 18 "pico-sdk/src/rp2_common/pico_platform_compiler/include/pico/platform/compiler.h" 3 4
# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/platform_defs.h" 1 3 4
# 19 "pico-sdk/src/rp2_common/pico_platform_compiler/include/pico/platform/compiler.h" 2 3 4
# 24 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 1 "pico-sdk/src/rp2_common/pico_platform_sections/include/pico/platform/sections.h" 1 3 4
# 25 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 1 "pico-sdk/src/rp2_common/pico_platform_panic/include/pico/platform/panic.h" 1 3 4
# 26 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 1 "pico-sdk/src/rp2_common/pico_platform_common/include/pico/platform/common.h" 1 3 4
# 27 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/regs/addressmap.h" 1 3 4
# 28 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/regs/sio.h" 1 3 4
# 29 "pico-sdk/src/rp2040/pico_platform/include/pico/platform.h" 2 3 4
# 65 "pico-sdk/src/common/pico_base_headers/include/pico.h" 2 3 4
# 1 "pico-sdk/src/common/pico_base_headers/include/pico/error.h" 1 3 4
# 66 "pico-sdk/src/common/pico_base_headers/include/pico.h" 2 3 4
# 13 "pico-sdk/src/rp2040/boot_stage2/include/boot_stage2/config.h" 2 3 4
# 12 "pico-sdk/src/rp2040/boot_stage2/compile_time_choice.S" 2






# 1 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 1
# 29 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
# 1 "pico-sdk/src/rp2040/pico_platform/include/pico/asm_helper.S" 1 3 4
# 9 "pico-sdk/src/rp2040/pico_platform/include/pico/asm_helper.S" 3 4
 # note we don't do this by default in this file for backwards comaptibility with user code
# that may include this file, but not use unified syntax. Note that this macro does equivalent
# setup to the pico_default_asm macro for inline assembly in C code.
.macro pico_default_asm_setup
.syntax unified
.cpu cortex-m0plus
.thumb
.endm


.macro regular_func x
.global \x
.type \x,%function
.thumb_func
\x:
.endm

.macro weak_func x
.weak \x
.type \x,%function
.thumb_func
\x:
.endm

.macro regular_func_with_section x
.section .text.\x
regular_func \x
.endm


.macro wrapper_func x
regular_func __wrap_\x
.endm

.macro weak_wrapper_func x
weak_func __wrap_\x
.endm

# backwards compatibility
.macro __pre_init func, priority_string
.section .preinit_array.\priority_string
.p2align 2
.word \func
.endm
# 30 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2

# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/regs/ssi.h" 1 3 4
# 32 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2
# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/regs/pads_qspi.h" 1 3 4
# 33 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2
# 89 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
pico_default_asm_setup

.section .text
# 100 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
regular_func _stage2_boot
    push {lr}





    ldr r3, =0x40020000
    movs r0, #(2 << 4 | 0x00000001)
    str r0, [r3, #0x00000004]
    ldr r0, [r3, #0x00000008]
    movs r1, #0x00000002
    bics r0, r1
    str r0, [r3, #0x00000008]
    str r0, [r3, #0x0000000c]
    str r0, [r3, #0x00000010]
    str r0, [r3, #0x00000014]

    ldr r3, =0x18000000


    movs r1, #0
    str r1, [r3, #0x00000008]


    movs r1, #2
    str r1, [r3, #0x00000014]







    movs r1, #1
    movs r2, #0x000000f0
    str r1, [r3, r2]





program_sregs:




    ldr r1, =((7 << 16) | (0x0 << 8))
    str r1, [r3, #0x00000000]


    movs r1, #1
    str r1, [r3, #0x00000008]


    movs r0, #0x35
    bl read_flash_sreg
    movs r2, #0x02
    cmp r0, r2
    beq skip_sreg_programming


    movs r1, #0x06
    str r1, [r3, #0x00000060]


    bl wait_ssi_ready
    ldr r1, [r3, #0x00000060]


    movs r1, #0x01
    str r1, [r3, #0x00000060]
    movs r0, #0
    str r0, [r3, #0x00000060]
    str r2, [r3, #0x00000060]

    bl wait_ssi_ready
    ldr r1, [r3, #0x00000060]
    ldr r1, [r3, #0x00000060]
    ldr r1, [r3, #0x00000060]


1:
    movs r0, #0x05
    bl read_flash_sreg
    movs r1, #1
    tst r0, r1
    bne 1b

skip_sreg_programming:


    movs r1, #0
    str r1, [r3, #0x00000008]
# 202 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
dummy_read:







    ldr r1, =((0x2 << 21) | (31 << 16) | (0x3 << 8))
    str r1, [r3, #0x00000000]

    movs r1, #0x0
    str r1, [r3, #0x00000004]
# 224 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
    ldr r1, =((8 << 2) | (4 << 11) | (0x2 << 8) | (0x1 << 0))
    ldr r0, =(0x18000000 + 0x000000f4)
    str r1, [r0]

    movs r1, #1
    str r1, [r3, #0x00000008]

    movs r1, #0xeb
    str r1, [r3, #0x00000060]
    movs r1, #0xa0
    str r1, [r3, #0x00000060]


    bl wait_ssi_ready





    movs r1, #0
    str r1, [r3, #0x00000008]





configure_ssi:
# 261 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S"
    ldr r1, =((0xa0 << 24) | (8 << 2) | (4 << 11) | (0x0 << 8) | (0x2 << 0))
    ldr r0, =(0x18000000 + 0x000000f4)
    str r1, [r0]

    movs r1, #1
    str r1, [r3, #0x00000008]





# 1 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/exit_from_boot2.S" 1
# 10 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/exit_from_boot2.S"
# 1 "pico-sdk/src/rp2040/hardware_regs/include/hardware/regs/m0plus.h" 1 3 4
# 11 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/exit_from_boot2.S" 2




check_return:
    pop {r0}
    cmp r0, #0
    beq vector_into_flash
    bx r0
vector_into_flash:
    ldr r0, =(0x10000000 + 0x100)
    ldr r1, =(0xe0000000 + 0x0000ed08)
    str r0, [r1]
    ldmia r0, {r0, r1}
    msr msp, r0
    bx r1
# 273 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2


# 1 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/wait_ssi_ready.S" 1
# 10 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/wait_ssi_ready.S"
wait_ssi_ready:
    push {r0, r1, lr}



1:
    ldr r1, [r3, #0x00000028]
    movs r0, #0x00000004
    tst r1, r0
    beq 1b
    movs r0, #0x00000001
    tst r1, r0
    bne 1b

    pop {r0, r1, pc}
# 276 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2

# 1 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/read_flash_sreg.S" 1
# 14 "pico-sdk/src/rp2040/boot_stage2/asminclude/boot2_helpers/read_flash_sreg.S"
.global read_flash_sreg
.type read_flash_sreg,%function
.thumb_func
read_flash_sreg:
    push {r1, lr}
    str r0, [r3, #0x00000060]

    str r0, [r3, #0x00000060]

    bl wait_ssi_ready

    ldr r0, [r3, #0x00000060]
    ldr r0, [r3, #0x00000060]

    pop {r1, pc}
# 278 "pico-sdk/src/rp2040/boot_stage2/boot2_w25q080.S" 2


.global literals
literals:
.ltorg

.end
# 19 "pico-sdk/src/rp2040/boot_stage2/compile_time_choice.S" 2

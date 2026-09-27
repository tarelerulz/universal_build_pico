// Derived from Life with David, RaspberryPiPico-BareMetalAdventures,
// Chapter 04. See THIRD_PARTY_LICENSES.txt.
// Updated to use symbolic Thumb handlers and one complete vector table.
.syntax unified
.cpu cortex-m0plus
.thumb
.section .vectors, "a"
.word __StackTop
.word _entry_point
.rept 46
.word default_handler
.endr
.section .text.default_handler, "ax"
.global default_handler
.thumb_func
default_handler:
    b default_handler


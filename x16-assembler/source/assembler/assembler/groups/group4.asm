; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       group4.asm
;       Purpose:    Assemble group 4 instruction (without operands)
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble group 4 instruction
;
; On entry, GroupTemp contains the line index
; ************************************************************************************************

AXGroup4:
;        ldx GroupTemp                   ; Recover the line index *** NOT NEEDED ***
        lda     AXBaseOpcode                ; just assemble the base opcode.
        jsr     AXWriteByte
        bit     write_error_flag            ; Was there a low-level error?
        bmi     _AXG4WriteError             ; Taken if so
        clc
        rts

_AXG4WriteError:
        rts


        


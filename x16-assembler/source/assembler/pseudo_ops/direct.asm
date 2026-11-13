; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       direct.asm
;       Purpose:    .direct command
;       Created:    26 March 2026
;       Original Author: Paul Robson (paul@robsons.org.uk)
;       Copied from "include.asm" and modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
; .direct sets a flag to tell the object code write function to save object code directly to memory.
; There are some address limitations, based on how the assembler was invoked.
;
; ************************************************************************************************

AXDirect:  ;; {.direct}

        lda #DIRECT_SET
        ora mem_flags
        sta mem_flags
        clc
        rts





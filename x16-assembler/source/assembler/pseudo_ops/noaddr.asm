; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       noaddr.asm
;       Purpose:    .noaddr command
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
; .noaddr sets a flag to tell the object code write function to produce an object file that
; does not have the two-byte load address. It has no effect if no object file is set.
;
; Use bload"<filename>",8,1,$<addr> to load such files.
;
; ************************************************************************************************

AXNoaddr:  ;; {.noaddr}

        
        lda #NOADDR_SET
        ora ops_flags
        sta ops_flags
        rts





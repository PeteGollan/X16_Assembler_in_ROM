; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       write.asm
;       Purpose:    Write byte A
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                       Write byte A
;
; ************************************************************************************************

AXWriteByte:
        pha                                 ; save registers
        phx
        phy

@cont:
        pha                                ; add to listing
        jsr AXAddListingByte
        pla

        ldx AXPass                         ; output pass#2 only.
        cpx #2
        bne @AXWBBumpPC

        tay                                ; char to Y.
        jsr TAWriteByte
        bcs @AXWBSkip                      ; Taken if error in AXAPIWriteByte
;
@AXWBBumpPC:        
        inc AXProgramCounter            ; bump PC
        bne @AXWBSkipPC
        inc  AXProgramCounter+1
@AXWBSkipPC:
        inc PCDirect                   ; bump PCDirect
        bne @AXWBSkip
        inc PCDirect+1
@AXWBSkip:        
        ply
        plx
        pla     ; If there was an error in AXAPIWriteByte, C=1 and write_error_code has the error
        rts






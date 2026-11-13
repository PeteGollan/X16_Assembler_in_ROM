; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       promote.asm
;       Purpose:    Promotes current address mode to absolute.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;       Promote current address mode to absolute from zero page, return CS if not possible
;       NOTE: Does *NOT* return an error code, just C=1 if error.
;
; ************************************************************************************************

        .macro axpromote arg1,arg2
        ldx     #arg2
        cmp     #arg1
        beq     AXDoPromote
        .endmacro

AXPromoteMode:
        lda     AXAddrMode
        axpromote  AXMZero,AXMAbsolute
        axpromote  AXMZeroX,AXMAbsoluteX
        axpromote  AXMZeroY,AXMAbsoluteY
        axpromote  AXMIndirect,AXMAbsoluteIndirect
        axpromote  AXMIndirectX,AXMAbsoluteIndirectX
        sec
        rts
AXDoPromote:
        stx     AXAddrMode      
        clc
        rts

        


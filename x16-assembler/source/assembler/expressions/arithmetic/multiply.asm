; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       multiply.asm
;       Purpose:    16 bit multiply
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"


; ************************************************************************************************
;
;                           Calculate Left := Left * Right 
;
; ************************************************************************************************

AXBinaryMult: ;; [*]
        lda     AXLeft                      ; copy left to temp
        sta     AXMTemp
        lda     AXLeft+1
        sta     AXMTemp+1
        stz     AXLeft                      ; zero left
        stz     AXLeft+1
@AXMultLoop:
        lda     AXMTemp                     ; bit 0 of old left set ?
        and     #1
        beq     @AXNoAdd
        jsr     AXBinaryAdd                 ; add right to left
@AXNoAdd:
        asl     AXRight                     ; shift right left
        rol     AXRight+1
        lsr     AXMTemp+1                   ; shift old left right
        ror     AXMTemp
        ;
        lda     AXMTemp                     ; loop back if old left still non-zero
        ora     AXMTemp+1
        bne     @AXMultLoop     
        clc
        rts


        .segment "VARS"

AXMTemp:
        .res   2



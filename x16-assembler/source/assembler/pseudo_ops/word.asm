; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       word.asm
;       Purpose:    .word command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble .word command
;
; ************************************************************************************************

AXWordCmd:  ;; {.word}
AXWordCmd2: ;; {.dw}
        ldx     AXOperandPos                ; get operand, must be defined even on pass 1.
;
@AXWLoop:
        jsr     AXPass2Expression           ; get value
        bcs     @AXWExit

        lda     AXLeft                      ; output the word.
        jsr     AXWriteByte

        bcs     @AXWWriteError              ; A-reg already has error code from AXWriteByte
        lda     AXLeft+1
        jsr     AXWriteByte
        bcs     @AXWWriteError              ; A-reg already has error code from AXWriteByte

        jsr     AXGet                       ; get next
        inx
        cmp     #','
        beq     @AXWLoop
        cmp     #0
        bne     @AXWSyntax
        clc
@AXWExit:       
        rts
@AXWSyntax:
        lda     #AXERRSyntax
        sec
        rts

@AXWWriteError:
        sec
        rts


        


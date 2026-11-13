; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       align.asm
;       Purpose:    .align command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   .align command
;
; ************************************************************************************************

AXXAlign:   ;; {.align}
        ldx     AXOperandPos                ; get operand, must be defined even on pass 1.
        jsr     AXExpressionDefined
        bcs     @AXAExit                    ; didn't work.
        ;
        lda     AXLeft                      ; if zero, exit (align 0)
        ora     AXLeft+1
        clc
        beq     @AXAExit
        ;
        lda     AXLeft+1                    ; copy MSB to +2 as defined, check one bit only set.
        sta     AXLeft+2
        lda     AXLeft                      ; keep shifting left until value in carry.
@AXAShift:
        asl     a
        rol     AXLeft+2
        bcc     @AXAShift
        ;
        ora     AXLeft+2                    ; if other bits set it's not a legal assign
        bne     @AXABad
        ;
        lda     AXLeft                      ; decrement AXLeft, makes it a mask.
        bne     @AXANoBorrow
        dec     AXLeft+1
@AXANoBorrow:       
        dec     AXLeft
        ;       
@AXAlign:
        lda     AXLeft                      ; if PC & Mask zero, exit okay
        and     AXProgramCounter
        bne     @AXAFill
        lda     AXLeft+1
        and     AXProgramCounter+1
        clc
        beq     @AXAExit
@AXAFill:       
        lda     #$00                        ; write one byte out
        jsr     AXWriteByte
        bit     write_error_flag            ; Was there a low-level error?
        bmi     @AXAExit                    ; Taken if so
        bra     @AXAlign

@AXABad:
        lda     #AXERRSize
        sec     
@AXAExit:
        rts


        


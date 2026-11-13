; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       shift.asm
;       Purpose:    Bit shifting binary operators.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                           Calculate Left := Left >> or << Right
;
; ************************************************************************************************

AXShiftLeft: ;; [<<]
        ldy     #0
        bra     AXShiftMain
AXShiftRight: ;; [>>]
        ldy     #$FF
AXShiftMain:
        lda     AXRight                     ; if shift > 15 then zero
        and     #$F0
        ora     AXRight+1
        bne     @AXShiftZero
        ;
        lda     AXRight                     ; shift zero, exit as unchanged.
        beq     @AXExit
        ;
@AXShiftLoop:   
        cpy     #0                          ; shift depending on direction flag in Y
        beq     @AXShiftLeft
        lsr     AXLeft+1
        ror     AXLeft
        bra     @AXShiftNext
@AXShiftLeft:
        asl     AXLeft
        rol     AXLeft+1
@AXShiftNext:
        dec     AXRight                     ; do required # of times
        bne     @AXShiftLoop
        clc                                 ; exit okay.        
        rts

@AXShiftZero:
        stz     AXLeft
        stz     AXLeft+1
@AXExit:        
        clc
        rts     

; ************************************************************************************************
;
;                                   Swap left and right
;
; ************************************************************************************************

AXSwap:
        pha
        phx
        lda     AXRight                     
        ldx     AXLeft
        sta     AXLeft
        stx     AXRight

        lda     AXRight+1
        ldx     AXLeft+1
        sta     AXLeft+1
        stx     AXRight+1

        lda     AXRight+2
        ldx     AXLeft+2
        sta     AXLeft+2
        stx     AXRight+2

        plx
        pla
        rts






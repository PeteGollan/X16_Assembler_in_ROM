; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       divide.asm
;       Purpose:    16 bit divide (unsigned)
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"


; ************************************************************************************************
;
;                           Calculate Left := Left / Right 
;
; ************************************************************************************************

AXBinaryDivide: ;; [/]
        lda     AXRight                     ; check divide by zero
        ora     AXRight+1
        beq     @AXDivZero
        ;
        stz     AXDTemp                     ; A = 0
        stz     AXDTemp+1
        ;
        ldy     #16                         ; iteration count.
@AXDivLoop:
        phy
        ;
        asl     AXLeft                      ; shift AQ left.
        rol     AXLeft+1
        rol     AXDTemp
        rol     AXDTemp+1
        ;
        sec                                 ; A-M => A:Y
        lda     AXDTemp
        sbc     AXRight
        tay
        lda     AXDTemp+1
        sbc     AXRight+1
        bcc     @AXDivNext                  ; if A < M exit
        ;
        sta     AXDTemp+1                   ; A = A - M
        sty     AXDTemp
        inc     AXLeft                      ; set bit 0 of the result.
@AXDivNext:
        ply
        dey 
        bne     @AXDivLoop
        clc
        rts     

@AXDivZero:
        lda     #AXERRDivZero
        sec
        rts

; ************************************************************************************************
;
;                           Calculate Left := Left % Right 
;
; ************************************************************************************************

AXBinaryModulus: ;; [%]
        jsr     AXBinaryDivide
        bcs     @AXBMExit
        lda     AXDTemp
        sta     AXLeft
        lda     AXDTemp+1
        sta     AXLeft+1
        clc
@AXBMExit:      
        rts

        .segment "VARS"
AXDTemp:
        .res   2       




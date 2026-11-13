; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       frames.asm
;       Purpose:    Push/Pull frame off stack
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Push frame on stack
;
; ************************************************************************************************

AXPushFrame:    
        sec                                 ; subtract frame size from stack, copy to AXTemp0
        lda     AXIStack
        sbc     #AXFrameSize
        sta     AXIStack
        sta     AXTemp0
        lda     AXIStack+1
        sbc     #0
        sta     AXIStack+1
        sta     AXTemp0+1
        ;
        ldy     #AXFrameSize                ; copy frame to stack space.

@AXPFCopy:
        dey
        lda AXStartFrame,y
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG  
        sta (AXTemp0),y
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        cpy #0
        bne @AXPFCopy       
        rts

; ************************************************************************************************
;
;                                   Pull frame off stack
;
; ************************************************************************************************

AXPullFrame:    
        clc                                 ; add frame size to stack, copy to AXTemp0
        lda     AXIStack
        sta     AXTemp0
        adc     #AXFrameSize
        sta     AXIStack

        lda     AXIStack+1
        sta     AXTemp0+1
        adc     #0
        sta     AXIStack+1
        ;
        ldy     #AXFrameSize                ; copy frame from stack space.
@AXPFCopy:
        dey
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda (AXTemp0),y
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        
        sta     AXStartFrame,y
        cpy     #0
        bne     @AXPFCopy       
        rts





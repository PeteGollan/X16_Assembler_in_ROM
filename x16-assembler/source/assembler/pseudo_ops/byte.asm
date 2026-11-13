; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       byte.asm
;       Purpose:    .byte command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble .byte command
;
; ************************************************************************************************

AXByteCmd:  ;; {.byte}
AXByteCmd2: ;; {.db}

        ldx     AXOperandPos                ; get operand, must be defined even on pass 1.

@AXBLoop:
        jsr     AXPass2Expression           ; get value
        bcs     @AXBExit

        lda     AXPass                      ; only check size on pass 2
        cmp     #2
        bne     @AXBNoCheck

        lda     AXLeft+1
        beq     @AXBNoCheck

        lda     #AXERRSize                  ; not a byte.
        sec
        rts

@AXBNoCheck:
        lda     AXLeft                      ; output the byte.
        jsr     AXWriteByte
        bcs     @AXBExit                    ; A-reg already has error code from AXWriteByte
        jsr     AXGet                       ; get next
        inx
        cmp     #','
        beq     @AXBLoop
        cmp     #0
        bne     @AXBSyntax
        clc
        rts
@AXBSyntax:
        lda     #AXERRSyntax
        sec
@AXBExit:       
        rts



        


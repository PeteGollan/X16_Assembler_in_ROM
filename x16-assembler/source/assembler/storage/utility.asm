; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       utility.asm
;       Purpose:    Identifier utility functions
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;       Compare current checked (text at AXTemp1, hash in AXHash) with record AXTemp0
;                               CC if match, CS if no match.
;
; ************************************************************************************************

AXICompareCurrent:
        ldy #1                          ; check the hashes match.
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda (AXTemp0),y
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        cmp AXIHash
        bne @AXICCFail                  ; they don't, fail.
        ;
        ldy #AXID_Identifier            ; compare identifier
@AXICCLoop:
        lda AXLabelBuffer-AXID_Identifier,y     ; get buffer entry

        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        cmp (AXTemp0),y                 ; compare against record entry.
        php
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        plp
        bne @AXICCFail                  
        ;
        iny                                 ; consume it
        asl a                           ; if it's bit 7 was clear, go back.
        bcc @AXICCLoop
        clc                                 ; matched !
        rts

@AXICCFail:
        sec
        rts

; ************************************************************************************************
;
;                       Calculate hash at AXTemp1 return in A/AXIHash
;
; ************************************************************************************************

AXICalculateHash:
        stz     AXIHash                     ; clear hash
        ldy     #0
@AXICHLoop:
        clc                                 ; add character, saving it
        lda     AXLabelBuffer,y
        iny
        pha
        adc     AXIHash
        sta     AXIHash
        pla                                 ; loop back if +ve
        bpl     @AXICHLoop
        lda     AXIHash                     ; return value.
        rts


        .segment "VARS"
AXIHash:
        .res 1




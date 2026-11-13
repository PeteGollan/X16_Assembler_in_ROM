; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       createfind.asm
;       Purpose:    Create/Find an identifier
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Create/Find an identifier in YX
;                                     CC = Found, CS = Created
;
; ************************************************************************************************

AXICreateFind:
        jsr AXIFind                     ; find it ?
        bcc @AXFound                    ; found so do nothing
        jsr AXICreate                   ; create new record
        sec                                 
@AXFound:
        rts

; ************************************************************************************************
;
;                                      Find an identifier in YX
;               CC = Found, AXTemp0 points to it CS = Not Found, AXTemp0 points to end
;
; ************************************************************************************************

AXIFind:
        stx AXTemp0                        ; save address at zTemp0
        sty AXTemp0+1
        jsr AXICalculateHash               ; calculate hash
        ;
        ;       Find the end, checking for duplicates as we go.
        ;

@AXIFindEnd:                               ; go to the end checking for duplicates.
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG       
        lda (AXTemp0)
        php
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        plp
        sec
        beq @AXIFindExit
        jsr AXICompareCurrent              ; compare AXTemp1 ident vs AXTemp0 record
        bcc @AXIFoundExit                  ; it's been found.
        ;
        clc                                ; go to next
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG    
        lda (AXTemp0)
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        adc AXTemp0
        sta AXTemp0
        bcc @AXIFindEnd
        inc AXTemp0+1
        bra @AXIFindEnd

@AXIFoundExit:
        jsr     AXISetCurrent
        clc

@AXIFindExit:       
        rts

; ************************************************************************************************
;
;                               Create identifier if not found
;
; ************************************************************************************************

AXICreate:  
        clc                                ; check memory short ?
        lda AXTemp0+1
        adc #2
        cmp AXIStack+1
        bcc @AXINoMemory
        dec AXIMemory                      ; set memory flag.
@AXINoMemory:       
        ldy #0 
        ;
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG      
@AXIFill:                                  ; fill +2,3,4,5 with zeros.     
        lda #0      
        sta (AXTemp0),y
        iny
        cpy #AXID_Identifier
        bne @AXIFill

@AXICopy:

        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG

        lda AXLabelBuffer-AXID_Identifier,y     ; copy name in from buffer.

        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG     
        sta (AXTemp0),y
        iny                                ; next character
        asl a                              ; keep going till bit 7 set.
        bcc @AXICopy

        lda #0                             ; write zero at end (end of list)
        sta (AXTemp0),y
      
        ;
        tya                                ; set the offset link.   
        sta (AXTemp0)
        ;
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG

        ldy #AXID_Hash                     ; fill the data in. +1 is the hash
        lda AXIHash
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG
        sta (AXTemp0),y
        ;
        ldy #AXID_Flags                    ; set the undefined flag.
        lda #$80
        sta (AXTemp0),y
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        sec                                 ; return CS, created
        ;       
@AXICFound:
        php                                 ; save carry
        jsr AXISetCurrent
        plp                                 ; restore carry.
        rts

AXISetCurrent:
        lda AXTemp0                        ; save as current record
        sta AXCurrent
        lda AXTemp0+1
        sta AXCurrent+1
        rts




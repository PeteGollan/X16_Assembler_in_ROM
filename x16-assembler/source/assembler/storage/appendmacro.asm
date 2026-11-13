; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       appendmacro.asm
;       Purpose:    Add the buffer string to the last defined word
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;           For the last defined label in the list, set type to Macro and ....
;
;           Add the ASCIIZ string in the buffer to the macro text with CR (Carry Clear)
;           Add $FF to macro text (Carry Set)
;
; ************************************************************************************************

AXIAppendMacro: 
        php                                 ; save end marker/line flag.
        ;   
        ;       Make AXTemp0 point to the *last* entry, which is a macro.
        ;
        lda     AXIBase
        sta     AXTemp0+1
        stz     AXTemp0                     ; save address at zTemp0
        ;

        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG      

@AXIFindLast:   
        lda     (AXTemp0)                   ; read the *next* link
        tay
        lda     (AXTemp0),y
        beq     @AXIFoundLast               ; if zero, we're at the last defined.
        ;
        tya                                 ; move to next.
        clc
        adc     AXTemp0
        sta     AXTemp0
        bcc     @AXIFindLast
        inc     AXTemp0+1
        bra     @AXIFindLast
@AXIFoundLast:
        ldy     #AXID_Type                  ; set the type to macro.
        lda     #AXIT_Macro
        sta     (AXTemp0),y

        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG

        plp                                 ; type of operation required.
        bcs     @AXIInsertNull
        
        ldx     #0                          ; insert the buffer
@AXIInsertBuffer:
        lda     AXBuffer,x                  ; if end of line insert $00 and exit
        beq     @AXIInsertA     
        jsr     @AXIInsert                  ; insert character
        inx                                 ; do next
        bra     @AXIInsertBuffer    
        ;
@AXIInsertNull:
        lda     #$FF                        ; insert a $FF marking macro end.
@AXIInsertA: 

        jsr @AXIInsert
        clc
        rts

@AXIInsert:
        phx
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG
        plx
        pha                                 ; save insertable.
        lda (AXTemp0)                       ; get offset to end.
        tay                                 ; now points to next free character
        pla                                 ; write new character out.
        sta (AXTemp0),y
        iny                                 ; write new end-next-link-zero
        lda #0
        sta (AXTemp0),y
        ;
        tya                                 ; bump length by one.
        iny
        sta (AXTemp0)
        phx
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        plx
        rts
        



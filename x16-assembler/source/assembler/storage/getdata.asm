; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       getdata.asm
;       Purpose:    Get address of associated data / Get line.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                       Get data address to YX
;
; ************************************************************************************************

AXIGetDataAddress:  
        lda     AXCurrent                   ; copy address for access
        sta     AXTemp0
        lda     AXCurrent+1
        sta     AXTemp0+1

        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG   

        ldy     #AXID_Identifier            ; point to name
@AXIFindEnd:                                ; find end of name.
        lda     (AXTemp0),y                 ; get next
        asl     a                           ; bit 7 to carry
        iny
        bcc     @AXIFindEnd
        ;
        tya                                 ; put address of data in YX.
        clc
        adc     AXTemp0
        tax
        lda     AXTemp0+1
        adc     #0
        tay

        phx                                 ; Preserve X-reg, part of YX return
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        plx

        rts

; ************************************************************************************************
;
;               Get line from AXMPointer to AXBuffer, CS if EOData, CC if okay
;
; ************************************************************************************************

AXIGetDataLine:
        lda     AXMPointer                  ; copy pointer to AXTemp0
        sta     AXTemp0
        lda     AXMPointer+1
        sta     AXTemp0+1
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG    
        lda     (AXTemp0)                   ; reached the end ?
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        cmp     #$FF
        sec                                 ; if so exit with CS.
        beq     @AXIExit
        ;
        ldy     #0                          ; copy data line to buffer.
@AXIGDLCopy:

        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG
        lda (AXTemp0),y
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG

        sta     AXBuffer,y
        iny
        cmp     #0
        bne     @AXIGDLCopy
        ;
        tya                                 ; Y is step to next line.
        clc     
        adc     AXMPointer
        sta     AXMPointer
        bcc     @AXIExitOkay
        inc     AXMPointer+1
@AXIExitOkay:
        clc                                 ; is okay.
@AXIExit:
        rts     





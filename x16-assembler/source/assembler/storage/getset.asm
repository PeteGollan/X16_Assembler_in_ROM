; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       getset.asm
;       Purpose:    Access offset data.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Get element Y => A
; The elements are:
; AXID_Type    
; AXID_Flags   
; AXID_DataLow 
; AXID_DataHigh
; AXID_DataAux
; AXID_Identifier
; ************************************************************************************************

AXIGet: 

        lda AXCurrent                      ; copy address for access
        sta AXTemp0
        lda AXCurrent+1
        sta AXTemp0+1

        phx
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda (AXTemp0),y                    ; read
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        plx
        
        rts

; ************************************************************************************************
;
;                                   Set element Y to A
;
; ************************************************************************************************

AXIPut: 
        pha
        lda     AXCurrent                  ; copy address for access
        sta     AXTemp0
        lda     AXCurrent+1
        sta     AXTemp0+1
        pla

        phx
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        sta (AXTemp0),y                    ; write
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        plx

        rts

; ************************************************************************************************
;
;                               Put Data YX to DataLow/High, and set flag
;
;                 Put can *FAIL* if defined and different - a redefinition error.
;
; ************************************************************************************************

AXIPutData: 
        lda     AXCurrent                   ; copy address for access
        sta     AXTemp0
        lda     AXCurrent+1
        sta     AXTemp0+1

        phx                                 ; Save x-reg which is an input pointer
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG
        plx                                 ; Restore x-reg which is an input pointer

        phy                                 ; save Y on stack.
        ldy     #AXID_Flags
        lda     (AXTemp0),y                 ; check if defined.
        bmi     @AXIPutOkay                 ; no, it is always okay to put.

        pla                                 ; get MSB back
        pha
        ldy     #AXID_DataHigh
        cmp     (AXTemp0),y
        bne     @AXIPutError                ; if value has changed, that's an error
        txa                                 ; check LSB
        ldy     #AXID_DataLow
        cmp     (AXTemp0),y
        bne     @AXIPutError                ; if value has changed, that's an error

@AXIPutOkay:
        pla
        ldy     #AXID_DataHigh              ; write high byte
        sta     (AXTemp0),y             

        txa
        ldy     #AXID_DataLow               ; write low byte
        sta     (AXTemp0),y             

        ldy     #AXID_Flags                 ; clear the 'defined' flag.
        lda     (AXTemp0),y
        and     #$7F
        sta     (AXTemp0),y
        
        phx
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        plx

        clc
        rts

@AXIPutError:
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        pla                                 ; throw saved Y
        lda     #AXERRRedefine
        sec     
        rts     




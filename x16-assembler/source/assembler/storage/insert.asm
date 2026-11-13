; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       insert.asm
;       Purpose:    Insert parameter from previous frame in current buffer
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;       Insert parameter A (0-n-1, one short) at position X in buffer. Parameter is obtained
;       from the *previous frame*
;
; ************************************************************************************************

AXIInsertParameter: 
        stx AXIPPosition                  ; save position & index
        sta AXIPIndex   

        lda AXIStack                      ; AXTemp0 points to previous frame.
        sta AXTemp0
        lda AXIStack+1
        sta AXTemp0+1

        lda AXIPIndex                      ; get the count of parameters
        ldy #(AXMParamCount-AXStartFrame)
        lda AXIPIndex                      ; compare index vs count
        
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG   
        cmp (AXTemp0),y
        php                                ; Save result of comparison
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        plp                                ; Restore result of comparison
        bcs  @AXIPError                    ; parameter error
        ;
        clc                                ; point into parameter array 
        adc #(AXMParameters-AXStartFrame)
        tay
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda (AXTemp0),y                    ; copy start and end offset
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        
        sta AXIPStart
        iny
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda (AXTemp0),y
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG   
        sta AXIPEnd
        ;
        ldx AXIPPosition                   ; move to end to check size and insert spaces.
@AXIPFindEnd:
        inx
        lda AXBuffer,x
        bne @AXIPFindEnd
        ;
        sec                                ; to position add length to insert
        txa                                ; (end-start)
        adc AXIPEnd
        sbc AXIPStart
        cmp #AXMaxLineSize                 ; line is too long ?
        bcs  @AXIPError
        ;
        tay                                ; now shift it up to make room.
@AXIPShiftUp:
        lda AXBuffer,x
        sta AXBuffer,y
        cpx AXIPPosition
        beq @AXIPShifted
        dex
        dey
        bra @AXIPShiftUp                
@AXIPShifted:
        ;
        ldy AXIPStart                     ; copy parameter data in place.
@AXIPCopy:
        phx                                ; Save x index
        ldx #ID_RAM_BANK                   ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG   
        lda (AXTemp0),y
        ldx #HOME_RAM_BANK                 ; ... and switch back
        stx RAM_BANK_REG
        plx                                ; Restore x index

        sta AXBuffer,x
        inx
        iny
        cpy AXIPEnd
        bne @AXIPCopy
        clc                                ; and successful.
        bra @AXIPExit

@AXIPError:
        lda #AXERRParam                    ; return bad parameter.
        sec
@AXIPExit:                                 ; exit
        rts


        .segment "VARS"
        
AXIPPosition:                              ; position in buffer
        .res 1  
AXIPIndex:                                 ; index-1 (e.g. \1 => 0)
        .res 1  
AXIPStart:                                 ; start position        
        .res 1  
AXIPEnd:                                   ; end position.     
        .res 1
        



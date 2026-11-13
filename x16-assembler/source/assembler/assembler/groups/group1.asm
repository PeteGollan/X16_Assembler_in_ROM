; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       group1.asm
;       Purpose:    Assemble group 1 (lda,sta,adc,cmp,sbc,and,eor,ora)
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble group 1 instruction
; Common to both 65C02 and 65C816 processors
;
; On entry, GroupTemp contains the line index
; ************************************************************************************************

AXGroup1:
        ldx GroupTemp                   ; Recover the line index
        jsr AXIdentifyAddressMode       ; get the address mode
        bcs @AXG1Exit                   ; syntax error (code in a-reg)
        lda AXAddrMode
        jsr AXGroup1Assemble_816        ; assemble group 1 with ZP/# mods.
        bit write_error_flag            ; Was there a low-level error?
        bmi @AXG1ErrorExit              ; Taken if so
        bcc @AXG1Exit                   ; Assemble worked!
        
        sta Temp0                       ; We failed Group1Assemble, so save error code
        jsr AXPromoteMode               ; promote addressing mode to try to fix the issue (e.g. addr too big for dp)
        lda Temp0                       ; recover any error code from previous failure
        
        bcs @AXG1Exit                   ; Couldn't promote addr mode, so exit with previous error code
        jsr AXGroup1Assemble_816        ; Try it with absolute addr mode.
        bit write_error_flag            ; Was there a low-level error?
        bmi @AXG1ErrorExit              ; Taken if so (error code is already in a-reg)
        bcc @AXG1Exit                   ; Assemble worked!
        lda #AXERRMode                  ; Otherwise, issue bad mode error.
@AXG1ErrorExit:
        sec
@AXG1Exit:        
        rts

; ************************************************************************************************
;
;       Try to assemble with current mode. If ZP check range. CS if failed, CC if succeeded.
;                               (should return error on STA #)
;
;       Note, the initial 8 modes are slightly different for the Group 1 set, see spreadsheet.
;
; ************************************************************************************************

AXGroup1Assemble_816:
        lda AXAddrMode                  ; Get address mode
        and #$7f                        ; Strip MSB
        tax
        bit sd_flags                    ; 65C816 set?
        bvs @table816
        lda G1AddrMode_table,x
        bra @TableCommon

@table816:
        lda G1AddrMode816_table,x       ; Get the offset

@TableCommon:
        sta Temp0                       ; Save the addr mode offset
        bmi @AXG1Fail                   ; $FF loaded, issue generic "address mode not supported"
                                        ; This could be a more refined message if required
                                        ; (e.g. wrong processor or instruction doesn't support)
                                        ; It would require assigning another bit to the table (b6)

@AXG1ModeOk:        
        lda AXAddrMode                  ; does the mode support 3 byte.
        bpl @AXGOperandOk               ; if so, we can't reject for being ZP.

        lda AXPass                      ; on pass 1, allow immediate always.
        cmp #2  
        beq @AXGCheckSize
        lda AXAddrMode
        cmp #AXMImmediate
        beq @AXGOperandOk
@AXGCheckSize:
        lda AXLeft+1                    ; fail if not a zero page operand.
        bne @AXG1Fail3                  ; Either 65C02 or 65C816 in 8-bit register mode
@AXGOperandOk:
        lda Temp0                       ; Recover the addr mode offset
        clc
        adc AXBaseOpcode
        cmp #$89                        ; cannot sta #
        beq @AXG1Fail
        jsr AXWriteByte                 ; write out the opcode.
        bcs @AXG1Fail2                  ; Write error A-reg already has error code.
        jsr AXWriteOperand              ; write the operand appropriately
        bcs @AXG1Fail2
        clc
        rts

@AXG1Fail:
        lda     #AXERRMode                  ; bad mode error.
        sec
        rts

; Low-level failure exit. Carry is already set and there is an error code in a-reg.
@AXG1Fail2:
        rts

; We tried a 16-bit immediate mode either on 65C02 or in 8-bit register mode
@AXG1Fail3:
        bit sd_flags            ; 65C816 mode?
        bvs @wrong_size         ; Taken if so
        lda #AXERRMode          ; Addr mode not supported
        sec
        rts

@wrong_size:
        lda #AXERRReq16         ; wrong register size error.
        sec
        rts

;-----------------------------------------------------------
; 65C816 Address Mode Table
; Addressing mode With the msb stripped off is the index.
; Non-allowed modes are set to $FF (test b7).
;-----------------------------------------------------------
G1AddrMode816_table:
.byte $08       ; AXMImmediate           $00  lda #$2A
.byte $04       ; AXMZero                $01  lda $2A
.byte $ff       ;x AXMAccumulator        $02  inc OR inc A
.byte $0c       ; AXMAbsolute            $03  lda $2ABC
.byte $10       ; AXMIndirectY           $04  lda ($2A),y
.byte $14       ; AXMZeroX               $05  lda $2A,x
.byte $18       ; AXMAbsoluteY           $06  lda $2ABC,y
.byte $1C       ; AXMAbsoluteX           $07  lda $2ABC,x
.byte $11       ; AXMIndirect            $08  ldx ($2A)
.byte $ff       ;x AXMZeroY              $09  lda $2A,y
.byte $ff       ;x AXMAbsoluteIndirect   $0A  jmp ($2ABC)
.byte $ff       ;x AXMAbsoluteIndirectX  $0B  jmp ($2ABC,x)
.byte $ff       ;x AXMRelative           $0C  bra $2A (not used)
.byte $00       ; AXMIndirectX           $0D  lda ($2A,x)
.byte $08       ; AXMImmediate2          $0E  lda #$1234 - 65C816 if .a16 (group 1) or .i16 (group 2) is set
.byte $02       ; AXMZeroS               $0F  lda $12,s - 65C816
.byte $12       ; AXMSRII                $10  lda ($12,s),y - 65C816
.byte $0e       ; AXMAbsLong             $11  lda $123456 - 65C816
.byte $1e       ; AXMAbsLongX            $12  lda $123456,x - 65C816
.byte $06       ;x AXMIndirectLong       $13  lda [$2A] - 65C816
.byte $16       ;x AXMIndirectLongY      $14  lda [$2A],y - 65C816
.byte $ff       ;x AXMxyc                $15  mvp #$12,#$32 - 65C816


;-----------------------------------------------------------
; 65C02 Address Mode Table
; Addressing mode With the msb stripped off is the index.
; Non-allowed modes are set to $FF (test b7).
;-----------------------------------------------------------
G1AddrMode_table:
.byte $08       ; AXMImmediate           $00  lda #$2A
.byte $04       ; AXMZero                $01  lda $2A
.byte $ff       ;x AXMAccumulator        $02  inc OR inc A
.byte $0c       ; AXMAbsolute            $03  lda $2ABC
.byte $10       ; AXMIndirectY           $04  lda ($2A),y
.byte $14       ; AXMZeroX               $05  lda $2A,x
.byte $18       ; AXMAbsoluteY           $06  lda $2ABC,y
.byte $1C       ; AXMAbsoluteX           $07  lda $2ABC,x
.byte $11       ; AXMIndirect            $08  lda ($2A)
.byte $ff       ;x AXMZeroY              $09  ldx $2A,y
.byte $ff       ;x AXMAbsoluteIndirect   $0A  jmp ($2ABC)
.byte $ff       ;x AXMAbsoluteIndirectX  $0B  jmp ($2ABC,x)
.byte $ff       ;x AXMRelative           $0C  bra $2A (not used)
.byte $00       ; AXMIndirectX           $0D  lda ($2A,x)
.byte $ff       ;x AXMImmediate2         $0E  lda #$1234 - 65C816 if .a16 (group 1) or .i16 (group 2) is set
.byte $ff       ;x AXMZeroS              $0F  lda $12,s - 65C816
.byte $ff       ;x AXMSRII               $10  lda ($12,s),y - 65C816
.byte $ff       ;x AXMAbsLong            $11  lda $123456 - 65C816
.byte $ff       ;x AXMAbsLongX           $12  lda $123456,x - 65C816
.byte $ff       ;x AXMIndirectLong       $13  lda [$2A] - 65C816
.byte $ff       ;x AXMIndirectLongY      $14  lda [$2A],y - 65C816
.byte $ff       ;x AXMxyc                $15  mvp #$12,#$32 - 65C816

; ************************************************************************************************
;
;                       Write operand in AXLeft according to AXAddrMode
;                         Note: this is common to all group handers.
; ************************************************************************************************

AXWriteOperand:
        lda AXAddrMode                  ; if Accumulator mode exit
        cmp #AXMAccumulator
        beq @AXWIs2Byte
                
        lda AXLeft                      ; output LSB
        jsr AXWriteByte
        bcs @AXG1WriteOpError           ; Write error. Error variable and flag  are set.
        lda AXAddrMode
        bmi @AXWIs2Byte
        lda AXLeft+1                    ; output MSB if wanted.
        jsr AXWriteByte
        bcs @AXG1WriteOpError           ;  Write error. Error variable and flag  are set.

; See if we have a 3-byte operand (absolute long and absolute long indexed):
        lda AXAddrMode
        cmp #AXMAbsLong
        beq @AXWIs3Byte                         ; Taken if so
        cmp #AXMAbsLongX
        bne @AXWIs2Byte                         ; Taken if NOT

; 65C816 Absolute Long and Absolute Long Index require a third byte:
@AXWIs3Byte:
        lda AXLeft_byte3                ; output the actual MSB
        jsr AXWriteByte
        bcs @AXG1WriteOpError           ;  Write error. Error variable and flag  are set.

@AXWIs2Byte:         
        rts

@AXG1WriteOpError:
        rts


        


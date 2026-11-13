; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       group2.asm
;       Purpose:    Assemble group 2 (ldx, asl and similar)
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
;                               Assemble group 2 instruction
;
; On entry, GroupTemp contains the line index
; ************************************************************************************************

AXGroup2:
        ldx GroupTemp                   ; Recover the line index
        jsr AXIdentifyAddressMode       ; get the address mode
        bcs @AXG2Exit                   ; syntax error (code in a-reg)
        lda AXAddrMode
        jsr  AXGroup2Assemble_816       ; assemble group2
        bit  write_error_flag           ; Was there a low-level error?
        bmi @AXG2ErrorExit              ; Taken if so
        bcc @AXG2Exit                   ; Assemble worked!

        sta Temp0                       ; We failed Group2Assemble, so save error code
        jsr AXPromoteMode               ; promote addressing mode to try to fix the issue (e.g. addr too big for dp)
        lda Temp0                       ; recover any error code from previous failure
        
        bcs @AXG2Exit                   ; Couldn't promote addr mode, so exit with previous error code
        jsr AXGroup2Assemble_816        ; Try it with absolute addr mode.
        bit write_error_flag            ; Was there a low-level error?
        bmi @AXG2ErrorExit              ; Taken if so (error code is already in a-reg)
        bcc @AXG2Exit                   ; Assemble worked!
        lda #AXERRMode                  ; Otherwise, issue bad mode error.
@AXG2ErrorExit:
        sec
@AXG2Exit:        
        rts

; ************************************************************************************************
;
;       Try to assemble with current mode. If ZP check range. CS if failed, CC if succeeded.
;                               (should return error on STA #)
;
;       Also test against the Fixup table which contains all the oddities.
;
; Since AXAddrMode is used directly in checks and opcode calculations, there are a few places
; were we substitute AXMImmediate2 for AXMImmediate (8-bit). This avoids having to place
; many x and y register instructions in group 2 in the "fixups" table.
; ************************************************************************************************

AXGroup2Assemble_816:
        lda AXAddrMode                  ; get the address mode
        cmp #AXMImmediate2              ; 16-bit immediate mode?
        bne @AXG2_cont1                 ; Taken if NOT
        lda #AXMImmediate
        and #$7F                        ; Strip off the "zero page" bit (so operand is 2 bytes)
        sta AXAddrMode                  ; Switch it
@AXG2_cont1:
        and #$1F                        ; if >= 8 will be in the oddballs table
        cmp #8 
        bcs @AX2CheckFixupList
        tax
        lda BitMaskTable,x              ; Get selector mask for the AddrMode
        and AXSelector                  ; Apply to bit pattern showing what is supported, what isn't.
        beq @AX2CheckFixupList          ; Taken if NOT supported (corresponding bit wasn't set).
        ;
        lda AXAddrMode                  ; if it is not zero page, then it's okay.
        bpl @AX2IsOkay

        lda AXPass                      ; for immediate check pass 2 only.
        cmp #2                          ; (see group 1)
        beq @AX2CheckSize
        lda AXAddrMode
        cmp #AXMImmediate
        beq @AX2IsOkay

@AX2CheckSize:
        lda AXLeft+1                    ; okay if zero page, and < 256
        bne @AXG2Fail3                  ; Either 65C02 or 65C816 in 8-bit register mode
@AX2IsOkay:
        lda #SD_OPCODE                  ; Is the instruction's "opcode" bit set?
        and AXFlags                     ; If set, it means opcode is a fixed value, not calculated.
        beq @not_opcode                 ; Taken if NOT (regular processing)
; This instruction has a fixed opcode, so set it up for the write:
        lda AXBaseOpcode                ; Get the fixed opcode...
        bra @AXG2_write                 ; ...and write it!
@not_opcode:
        lda AXAddrMode                  ; mode x 4
        and #$1F
        asl a
        asl a
        adc AXBaseOpcode
@AXG2_write:
        jsr AXWriteByte                     ; write out the opcode.
        bcs @AXG2WriteError                 ; Write error A-reg already has error code.     
        jsr AXWriteOperand                  ; write the operand appropriately,
        clc
        rts
;
; Didn't work. Let's try this mode and base opcode against the fix up list.
;
@AX2CheckFixupList:
        lda #SD_FIXUP                       ; Is the fixup flag SET for this instruction?
        and AXFlags
        beq @AX2Fail                        ; Taken if NOT (i.e. don't check the fixup table) 

; The fixup flag was SET, so look in the fixup table:
        lda AXAddrMode                      ; fail if zero page address mode and non-zp operand.
        bpl @AX2CheckFixup
        lda AXLeft+1
        bne @AX2Fail
@AX2CheckFixup:             
        ldx     #0
@AX2FixupLoop:
        lda AXGroup2OpcodeFixupTable816,x   ; base opcode
        beq @AX2Fail
        cmp AXBaseOpcode                    ; if opcodes dont match go to next.
        bne @AX2Next
        lda AXGroup2OpcodeFixupTable816+1,x ; address mode
        cmp AXAddrMode
        beq @AX2Found                       ; found a match
@AX2Next:       
        inx                                 ; next table entry
        inx
        inx
        inx                                 ; NOW 4 bytes per entry
        bra @AX2FixupLoop
        ;
@AX2Found:
; We found the entry, but make sure it is valid for the current processor mode:
        lda sd_flags
        and #$C0                            ; keep only the processor flags (future proofing this variable)
        bit AXGroup2OpcodeFixupTable816+3,x ; Non-zero if fixup is compatible with current processor mode.
        beq @AX2Fail                        ; Taken if NOT compatible (bad mode)
        lda AXGroup2OpcodeFixupTable816+2,x ; get actual opcode
        jsr AXWriteByte
        bcs @AXG2WriteError                 ; Write error A-reg already has error code.     
        jsr AXWriteOperand                  ; write the operand appropriately,
        clc
        rts

@AX2Fail:
        lda #AXERRMode                      ; bad mode error.
        sec
        rts

; We tried a 16-bit immediate mode either on 65C02 or in 8-bit register mode or
; on an instruction with the imm8 flag set.
@AXG2Fail3:
        lda #SD_IMM8            ; Is the instruction's "imm8" bit set?
        and AXFlags             ; If set, it means immediate is ALWAYS 8 bits.
        bne @wrong_mode         ; Taken if SET

        bit sd_flags            ; 65C816 mode?
        bvs @wrong_size         ; Taken if so
@wrong_mode:
        lda #AXERRMode          ; Addr mode not supported
        sec
        rts

@wrong_size:
        lda #AXERRReq16         ; wrong register size error.
        sec
        rts

@AXG2WriteError:
        rts

; Indexed by the first 8 AddrMode entries:
BitMaskTable:
        .byte %10000000         ; 0
        .byte %01000000         ; 1
        .byte %00100000         ; 2
        .byte %00010000         ; 3
        .byte %00001000         ; 4
        .byte %00000100         ; 5
        .byte %00000010         ; 6
        .byte %00000001         ; 7

        


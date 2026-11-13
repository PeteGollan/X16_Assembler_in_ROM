; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       addressmode.asm
;       Purpose:    Identify the address mode/operand for the post opcode part of the instruction.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       October 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                   Work out the address mode from X , store in AXAddrMode
;                          CC if okay, CS if error with error in A.
;                            Expressions evaluated as per pass 2.
;
; ************************************************************************************************

AXIdentifyAddressMode:

; ----------------------------------------------------------------------------------------
;
;                           First check for ASL/ASL A
;
; ----------------------------------------------------------------------------------------

        jsr     AXGet                       ; has two formats, ASL and ASL A
        cmp     #0
        beq     @AXIsAccumulator
        cmp     #ASCII_A
        bne     @AXCheckImmediate

        lda     AXBuffer+1,x                ; is the A followed by space/eol
        cmp     #' '+1
        bcs     @AXCheckImmediate
@AXIsAccumulator:
        lda     #AXMAccumulator     
        sta     AXAddrMode
@AXIsOkay:      
        clc
@AXExit:        
        rts

;----------------------------------------------------------------------------------------
;
;   Check for Immediate #xx or #xxxx, Indirect ($xx), and Indirect Long [$xx]
;
;----------------------------------------------------------------------------------------

@AXCheckImmediate:      
        cmp #'#'                        ; Immediate?
        beq @AXIsImmediate
        cmp #'('                        ; Indirect?
        bne @not_ind                    ; Taken if NOT
        jmp @AXIsIndirect
@not_ind:
        cmp #'['                        ; Indirect long?
        bne @AXCheckDirect              ; Taken if NOT
        jmp @AXIsIndirectLong

; ----------------------------------------------------------------------------------------
;
;                               nnnn nnnn,x or nnnn,y
;
; ----------------------------------------------------------------------------------------
@AXCheckDirect:
        jsr AXPass2Expression           ; evaluate base address
        bcs @AXExit                     ; error in that.
        jsr AXGet                       ; what follows
        beq @AXIsDirect                 ; nothing, nnnn
        cmp #','                        ; if not needs to be ,X ,Y
        bne @AXSyntax
        inx
        jsr AXGet                       ; what follows should be X or Y
        tay
        lda #AXMZeroX                   ; check for ,X ,Y, S
        cpy #ASCII_X
        beq @AXIsZeroX                  ; 
        lda #AXMZeroY
        cpy #ASCII_Y
        beq @AXExitOkay
        lda #AXMZeroS                   ; Check for nn,s (stack relative)
        cpy #ASCII_S
        beq @AXExitOkay

; Note: updates to this must also be made to @AXSyntax2
@AXSyntax: 
        lda #AXERRSyntax
        sec
        rts

;-------------------------------------------------------------------------------------------
; 65C816 - check for absolute long,x (>16 bits) and substitute if so
; See "note" below.
; On entry a-reg has #AXMZeroX.
@AXIsZeroX:
        ldy AXLeft_byte3        ; Was it > 16 bits?
        beq @AXExitOkay         ; Taken if NOT (24-bit MSB is zero)
        lda #AXMAbsLongX        ; Change the mode
@AXExitZeroX:
        bra @AXExitOkay

;------------------------------------------------------------------------------------------------
; 65C816 - check for absolute long (>16 bits) and substitute if so
; Note: This check of the operand *ONLY* works because we only support long CONSTANTS.
;       If this code is ever updated to allow long symbols, they would either have to already
;       be defined or there would have to be some way to specify that long is used.
;------------------------------------------------------------------------------------------------
@AXIsDirect:
        lda #AXMZero            ; Assume one of the direct modes (will get promoted if not)
        ldy AXLeft_byte3        ; Was it > 16 bits?
        beq @AXExitOkay         ; Taken if NOT (24-bit MSB is zero)
        lda #AXMAbsLong         ; Change the mode
@AXExitOkay:        
        sta AXAddrMode
        clc
        rts

; ----------------------------------------------------------------------------------------
;
;                                           Immediate
; Modified for 65C816
; If 65C816 is set, it returns AXMImmediate2 (16-bit immediate) if the appropriate
; register flag is set: .a16 for group 1 + group 2 BIT and .i16 for the rest of group 2.
; UNLESS the instruction has SD_IMM8, in which case it is always 8 bit.
;
; Also processes xyc addressing mode: #$aa,#$bb
; ----------------------------------------------------------------------------------------

@AXIsImmediate:
        inx                                ; consume the #
        jsr AXPass2Expression              ; get operand
        bcs @AXExit                        ; bad operand

; Check for the 65C816 xyc addressing mode: #$ab,#$cd
        jsr AXGet                          ; What follows?
        beq @AXIsImmediate2                ; If nothing, it is immediate
        
; Check that the operand is 8 bits:
        ldy AXLeft+1                       ; Is the MSB zero?
        beq @xyc_ok                        ; Taken if SO (8 bit)
; Exit here:        
@BadOperand8_err:
        lda #AXERRBadOperand8
        sec
        rts

; Get the second 8-bit operand:
@xyc_ok:
        ldy AXLeft                         ; Save the first operand for now
        sty Temp0
        cmp #','                           ; If something, it must be ,#xx
        bne @AXSyntax                      ; Taken if NOT
        inx                                ; consume the ","
        jsr AXGet                          ; Expecting "#"
        bne @xyc_ok2                       ; Taken if someting
        jmp @AXSyntax                      ; We had "#$xx," so error exit
@xyc_ok2:
        cmp #'#'                           ; Is it a "#"?
        beq @xyc_ok3                       ; Taken if we got the "#"
        jmp @AXSyntax                      ; Taken if not (basically, garbage on line)
@xyc_ok3:
        inx                                ; consume the #
        jsr AXPass2Expression              ; get operand
        bcc @xyc_check_op2                 ; Taken if second operand is OK
        jmp @AXSyntax                     ; bad operand

; Check that the second operand is 8 bits:
@xyc_check_op2:
        lda AXLeft+1                       ; Is the MSB zero?
        bne @BadOperand8_err               ; Taken if NOT

; Success. Put the two operands togethers and exit:
        lda Temp0
        sta AXLeft+1                       ; MSB
        lda #AXMxyc                        ; Return the "xyc" addressing mode via success exit.
        bra @imm_exit

@AXIsImmediate2:
; If the SD_IMM8 flag is set for this instruction, then immediate is ALWAYS 8 bits:
        lda #SD_IMM8                        ; Is the instruction's "imm8" bit set?
        and AXFlags                         ; If set, it means immediate is ALWAYS 8 bits.
        bne @imm8bit                        ; Taken if SET

        bit     sd_flags                   ; 65C816 mode?
        bvc     @imm8bit                   ; Taken if NOT

; The exception for group 1 - acc, group 2 - index is BIT (group 2, but uses acc):
        lda AXBaseOpcode
        cmp #BaseOpcode_BIT     ; Is it BIT (group 2, but uses acc, so group 1 handling)
        beq @acc_size           ; Taken if so

        lda AXGroup
        cmp #1                  ; 65C816 group 1?
        bne @not1               ; Taken if NOT
@acc_size:
        bit rs_flags            ; 65C816 group 1 (and group 2 BIT) - is the a-reg set for 16-bit?
        bpl @imm8bit            ; Taken if NOT
        lda #AXMImmediate2      ; 16-bit is set, so use the 2-byte immediate
        bra @imm_exit
@not1:
        cmp #2                  ; 65C816 group 2?
        bne     @imm8bit        ; Taken if NOT

        bit rs_flags            ; 65C816 group 2 - are the index regs set for 16-bit?
        bvc @imm8bit            ; Taken if NOT
        lda #AXMImmediate2      ; 16-bit is set, so use the 2-byte immediate
        bra @imm_exit

@imm8bit:
        lda     #AXMImmediate               ; return immediate

@imm_exit:
        sta     AXAddrMode
        clc
        rts

; ----------------------------------------------------------------------------------------
;
;                           indirect (nnnn) (nnnn,x) or (nnnn),y
;
; ----------------------------------------------------------------------------------------

@AXIsIndirect:      
        inx
        jsr AXPass2Expression           ; the address to indirect through
        jsr AXGet                       ; what follows.
        cmp #','                        ; if , then check for indirect X
        beq @AXIndirectX
        cmp #')'                        ; otherwise must be closing bracket
        bne @AXSyntax2
        inx                                 ; consume )

; ----------------------------------------------------------------------------------------
;
;                       indirect (nnnn) or indirect y (nnnn),y
;
; ----------------------------------------------------------------------------------------

        jsr AXGet                       ; if nothing follows it is (xxx)
        beq @AXIndirect 
        cmp #','                        ; otherwise must be ,Y
        bne @AXSyntax2
        inx
        jsr AXGet
        cmp #ASCII_Y
        bne @AXSyntax2
        ;
        lda #AXMIndirectY               ; indirect Y
        sta AXAddrMode
        clc
        rts

@AXIndirect:                                ; indirect
        lda #AXMIndirect
        sta AXAddrMode
        clc
        rts

;----------------------------------------------------------------------------------------
;
; 65C816 - Indirect long [nn] or Indirect Long Indexed [nn],y
;
;----------------------------------------------------------------------------------------

@AXIsIndirectLong:      
        inx
        jsr AXPass2Expression           ; the address to indirect through
        jsr AXGet                       ; what follows?
        cmp #']'                        ; closing square bracket is indirect long of some sort
        bne @AXSyntax2
        inx                                 ; consume "]""

        jsr AXGet                       ; if nothing follows it is (xxx)
        beq @AXIndirectLong 
        cmp #','                        ; otherwise must be ,Y
        bne @AXSyntax2
        inx
        jsr AXGet
        cmp #ASCII_Y
        bne @AXSyntax2
        ;
        lda #AXMIndirectLongY               ; indirect long Y
        sta AXAddrMode
        clc
        rts

@AXIndirectLong:                                ; indirect long [d]
        lda #AXMIndirectLong
        sta AXAddrMode
        clc
        rts

; Closer version of @AXSyntax
@AXSyntax2:
        lda #AXERRSyntax
        sec
        rts
; ----------------------------------------------------------------------------------------
;
;                               Indirect X (nnnn,x)
; ----------------------------------------------------------------------------------------

@AXIndirectX:
        inx                                 ; consume comma

        jsr AXGet                       ; check x
        cmp #ASCII_X
        bne @AXSRII                     ; Nope, got check for SRII: ($12,s),y

@IndirectX_found:
        inx     
        jsr AXGet                       ; check )
        cmp #')'
        bne @AXSyntax2

        lda #AXMIndirectX               ; it's indirect X
        sta AXAddrMode
        clc
        rts

; ----------------------------------------------------------------------------------------
;                         Stack Relative indirect indexed ($12,s),y
; ----------------------------------------------------------------------------------------

@AXSRII:

        cmp #ASCII_S             ; Stack relative?
        bne @AXSyntax2           ; Taken if not

        inx     
        jsr AXGet                       ; check )
        cmp #')'
        bne @AXSyntax2

; Just need ",y" to complete the addressing mode:


        inx
        jsr AXGet
        cmp #','
        bne @AXSyntax2           ; Taken if not

        inx
        jsr AXGet
        cmp #ASCII_Y
        bne @AXSyntax2          ; Taken if NOT

        lda #AXMSRII            ; It's Stack Relative Indirect Indexed (SRII) ($12,s),y
        sta AXAddrMode
        clc
        rts


       




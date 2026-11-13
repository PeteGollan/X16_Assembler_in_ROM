; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       assemble.asm
;       Purpose:    Assemble a line from the source
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       May 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;               Assemble line in buffer. Returns CS on error, error code in A.
;
; ************************************************************************************************

; These MUST be upper case ASCII:
condasm_key0:       .byte "endif",$00       ; Start with the most likely one
condasm_key1:       .byte "else",$00

AXAssembleLine:

        lda     AXIMemory                   ; out of memory ?
        beq     @AXALMemOkay
        lda     #AXERRMemory                ; if so, report it.
        sec
        rts

@AXALMemOkay:
        bit condasm_flags                       ; Are we skipping lines in a conditional block?
        bvc @AXAProcessLine                     ; Taken if not (condasm_flags b6 CONDASM_SKIP flag is clear)

;-------------------------------------------------------------------------------------------------
; We are skipping lines in a conditional assembly block, but scan for .else or .endif and allow
; them through. This is done inline to reduce the processing impact.
;-------------------------------------------------------------------------------------------------

; Look for '.' to indicate possible .else or .endif:
        ldx #0                          ; Start of line
@next0:
        lda AXBuffer,x
        beq @AXASkipLine                ; End of line, no '.', so skip this line
        cmp #'.'
        beq @check_condasm              ; see if this is .else or .endif
        inx
        bne @next0

; see if this is .else or .endif
@check_condasm:
        inx     ; Point to first char in potential condasm keyword (endif or else) in the buffer
        stx Temp0 ; Save buffer index for the second keyword check
        ldy #0  ; Points to the character in the reference keyword
@next1:
        lda condasm_key0,y      ; Fetch a character from the first keyword
        beq @AXAProcessLine     ; End of keyword means We have a match so process it
        cmp  AXBuffer,x         ; Match?
        bne @check_key2         ; Taken if not (no match, so check next keyword)
@match1:
        inx                     ; Next character
        iny
        bra @next1

@check_key2:
        ldx Temp0               ; Recover original buffer index for the second keyword check
        ldy #0
@next2:
        lda condasm_key1,y      ; Fetch a character from the second keyword
        beq @AXAProcessLine     ; End of keyword means We have a match so process it
        cmp  AXBuffer,x         ; Match?
        bne @AXASkipLine        ; Taken if not (no match, so skip the line)
@match2:
        inx                     ; Next character
        iny
        bra @next2

; condasm_skip is set and we didn't find any keywords, so skip the line:
@AXASkipLine:
        clc                     ; No error, just skip the line
        rts

@AXAProcessLine:
        lda     AXProgramCounter            ; copy program counter to program counter start
        sta     AXProgramCounterStart       ; this is the value used in the unary function *
        lda     AXProgramCounter+1
        sta     AXProgramCounterStart+1

        bit logical_flag                   ; Is logical set?
        bpl @not_logical                   ; Taken if NOT

; If .logical is set, copy PCDirect to PCDirectStart (the physical program counter). This is used in listing output.
        lda     PCDirect
        sta     PCDirectStart
        lda     PCDirect+1
        sta     PCDirectStart+1

@not_logical:
        stz     id_count                    ; Clear identifier found on this line count.
        stz     id_valid_flag               ; Clear identifier valid flag

        stz     AXListCount                 ; clear the listing bytes.
        ldx     #0                          ; start of line
        
@AXAContinue:       
        jsr     AXGet                       ; get first character
        cmp     #0
        bne     @AXHasText
        clc                                 ; if 0, empty line, exit with carry clear
        rts

        ; ========================================================================================
        ;
        ;               Two options , it's * = <xxxx> or a label/instruction
        ;
        ; ========================================================================================

@AXHasText:
        cmp     #'*'                        ; is it * (for * = )
        bne     @not_org                    ; Swapped around due to branch out of range
        jmp     @AXSetPC

@not_org:
        ;
        cpx #0                              ; Identifier at start of line?
        bne @not_org1                       ; Taken if not

        stz id_valid_flag
        dec id_valid_flag                   ; Set id_valid flag if id was at start of line

@not_org1:
        jsr     AXExtractIdentifier         ; get an identifier 
        bcc     @AXCheck_SysWord

; if none found, report it as a syntax error.
@AXSyntax:
        lda     #AXERRSyntax
        sec
@AXExit:        
        rts     

        ; ========================================================================================
        ;
        ;                   Check if it's a system word, if so, process that.
        ;
        ; ========================================================================================
@AXCheck_SysWord:
        phx                                 ; look in system dictionary (opcodes, pseudo ops etc).
        ldx #<AXSystemDictionary816
        ldy #>AXSystemDictionary816
        jsr AXIFind
        plx
        bcs @AXALabel                   ; not found, label check.
        ;
        phx
        ldy #AXID_Type                  ; get the type
        jsr AXIGet
        plx
        ;
        cmp #AXIT_Opcode                ; different code for opcode, macro, pseudo-op.
        beq @AXAOpcode
        cmp #AXIT_Macro
        beq @AXAMacro
        cmp #AXIT_PsuedoOp
        beq @handle_pseudo_ops              ; Switched around due to branch out of range
        jmp @AXSyntax
        ;
        ; ========================================================================================
        ;
        ;                               Handle pseudo-operations
        ;
        ; ========================================================================================

@handle_pseudo_ops:
        stx     AXOperandPos                ; save the operand position.
        ldy     #AXID_DataLow               ; get the code address and jump there.
        jsr     AXIGet
        sta     AXVector
        ldy     #AXID_DataHigh
        jsr     AXIGet
        sta     AXVector+1
        jmp     (AXVector)

@AXAMacro:
        jmp     AXPAssembleMacro

@AXAOpcode:
        jmp AXPAssembleOpcode   

        ; ========================================================================================
        ;
        ;                   Not a mnemonic, so it's a label of some sort.
        ;
        ; ========================================================================================

@AXALabel:
        phx
        ldy     AXIBase                     ; start scanning.
        ldx     #0
        jsr     AXICreateFind               ; find it, or create it if necessary.
        plx

        jsr     AXGet                       ; if followed by '.' cannot be macro invocation
        cmp     #'.'
        bne @check_for_macro

        stz id_valid_flag
        dec id_valid_flag               ; Set id_valid flag since there is a "." on the line
        bra @AXANotMacro

@check_for_macro:
        phx
        ldy     #AXID_Type                  ; get the type.
        jsr     AXIGet
        plx

        cmp     #AXIT_Macro                 ; if macro, go to macro code.
        beq     @AXAMacro

@AXANotMacro:
        jsr AXProcessLabel              ; process the label.

        bcs @AXANotMacroExit            ; Switched up due to branch range
        jmp @AXAContinue                ; if okay, try the line again.

@AXANotMacroExit:
        rts                                 ; return with error.

        ; ========================================================================================
        ;
        ;                               Set the PC (* = <expr>)
        ;
        ; ========================================================================================
@AXSetPC:
        inx                                 ; get next.
        jsr  AXGet
        cmp  #'='                           ; must be equals.
        beq @AXGet_ok                       ; Swapped around due to branch out of range
        jmp @AXSyntax
@AXGet_ok:
        inx
        jsr  AXExpressionDefined           ; get an expression, must be defined.
        bcc @AXGet_expression_ok           ; Swapped around due to branch out of range
        jmp @AXExit                        ; error of some sort.

@AXGet_expression_ok:     

        bit logical_flag                   ; Are we in a .logical block?
        bpl @set_PC_ok                     ; Taken if NOT

; Attempt to set PC within a .logical block so error:
        lda #AXERROrgLogical
        sec
        rts

@set_PC_ok:        
        lda AXLeft                          ; copy result to current PC
        sta AXProgramCounter
        lda AXLeft+1
        sta AXProgramCounter+1

; If .direct assembly is enabled, check for addresses in RAM and ROM bank ranges
; and ensure that .bank and .rombank are set:

        cmp #$A0                           ; Banked RAM/ROM range?
        bcc @pc_ok                         ; Taken if not (PC < $A0xx_
        tax                                ; Save the PC MSB
        lda #DIRECT_SET                    ; Are we in .direct mode?
        and mem_flags
        beq @pc_ok                         ; Taken if not

        txa                                ; A-reg has PC MSB
        ; A-reg has PC MSB:
        and #%11100000                     ; We just need the top three bits
        cmp #%10100000                     ; Bank RAM? ($Axxx-$Bxxx)
        beq @check_ram

; It is not bank RAM, so it must be ROM:

; Check for .rombank:
        lda #ROM_BANK_ENABLED              ; Are we also in .rombank mode?
        and mem_flags
        bne @pc_ok                          ; Taken if so

; Error.. require .rombank for direct assembly into $Cxxx-$Fxxxx
        lda #AXERRROMBankReq
        sec
        rts
     
@check_ram:
        lda #RAM_BANK_ENABLED              ; Are we also in .bank mode?
        and mem_flags
        bne @pc_ok                          ; Taken if so

; Error.. require .bank for direct assembly into $Axxxx-$Bxxxx
        lda #AXERRBankReq
        sec
        rts

@pc_ok:
        clc                                 ; and done successfully.
        rts

; ************************************************************************************************
;
;           Label (e.g. unknown identifier) in buffer. Decide what to do with it
;
; ************************************************************************************************

AXProcessLabel:
        lda     AXPass                      ; don't set the type on pass 2
        cmp     #2
        beq     @AXPLNoSet
        phx                                 ; set type to label/identifiier.
        lda     #AXIT_Label
        ldy     #AXID_Type
        jsr     AXIPut
        plx
@AXPLNoSet:     
        inc     id_count                    ; Bump identifier found on this line count. Used by .macro
        jsr     AXGet                       ; what is next
        beq     @AXLabelPC                  ; nothing, it's a program counter label
        cmp     #':'                        ; if label: then it's a program counter label.
        beq     @AXPCTR                     ; (we have to consume the :)

        jsr     AXIsIdentifierHead          ; some identifier follows.
        bcc     @AXLabelPC                  ; then it's a program counter label.
        ;
        inx                                 ; consume it anyway.
        cmp     #'='                        ; must be '=' something
        beq     @AXAssignValue              ; yes, assign value
        ;
        lda     #AXERRSyntax                ; otherwise syntax error
        sec
@AXPExit:       
        rts

        ; ========================================================================================
        ;
        ;               It's a label PC e.g. <label> <command> or <label>:
        ;
        ; ========================================================================================

@AXPCTR:

; We reached here because there was a ":" on the end of the id/label, so mark it valid:
        stz id_valid_flag
        dec id_valid_flag               ; Set id_valid flag since there is a "." on the line
        inx                                 ; consume ":"
@AXLabelPC:

; This is a "program counter" id/label, but to prevent typos from silently turning into labels (e.g. a mistyped mnemonic),
; we have requirements for a valid id/label.

        lda id_valid_flag       ; Does this meet the criteria?
        bne @AXLabelPC_valid    ; Taken if so

        lda #AXERRSyntax        ; id/label is not valid, so exit with a syntax error
        sec
        rts

@AXLabelPC_valid:
        phx                                 ; save position
        ldx     AXProgramCounter
        ldy     AXProgramCounter+1
        jsr     AXIPutData                  ; write it.
        bcs     @AXRedefine
        ;
        lda     RAM_bank                    ; write the bank
        ldy     #AXID_DataAux
        jsr     AXIPut

        lda     AXLabelBuffer               ; is it a non local label ?
        cmp     #ASCII_UNDERSCORE
        beq     @AXNotGlobal
        cmp     #'@'
        beq     @AXNotGlobal
        jsr     AXIBumpLocal                ; we need new locals.
@AXNotGlobal:       
        plx                                 ; restore position
        clc
        rts                                 ; return with that error code.

@AXRedefine:                                ; redefined so probably out of sync.
        plx
        sec
        rts

        ; ========================================================================================
        ;
        ;                           It's label = <expression>
        ;
        ; ========================================================================================

@AXAssignValue:
        lda     AXCurrent                   ; save current identifier
        pha
        lda     AXCurrent+1
        pha

        jsr     AXExpressionDefined         ; evaluate expression

        pla                                 ; restore current identifier.
        sta     AXCurrent+1
        pla
        sta     AXCurrent

        bcs     @AXPExit                    ; exit on error.

        phx
        ldx     AXLeft                      ; set to the result
        ldy     AXLeft+1                    ; preserving X
        jsr     AXIPutData
        plx
        rts


        .segment "VARS"
AXOperandPos:                               ; data in buffer starts here.
        .res   1       
AXVector:                                   ; for calling psuedo op code
        .res   2

        


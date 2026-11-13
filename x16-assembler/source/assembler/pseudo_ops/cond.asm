; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       cond.asm
;       Purpose:    .if/.ifdef/ifndef/.else/.endif/.assert pseudo_ops
;       Created by: Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       September 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               .assert <exp>
;
; ************************************************************************************************

AXAssertCmd:  ;; {.assert}

        ldx AXOperandPos                ; Get operand, must be defined even on pass 1.
        jsr AXGet                       ; What follows?
        cmp #0
        bne @GetExpression              ; Taken if there is an expression

        lda #AXERRSyntax                ; No expression for .assert, so syntax error.
        sec
        rts

@GetExpression:
        jsr AXPass2Expression           ; get value
        bcs @AXIExit                    ; Taken if error, C is set and A-reg has error code

        lda AXLeft
        ora AXLeft+1                        ; OR the LSB and MSB, if it is still zero, the expression is FALSE.
        beq @false

; Non-zero expression is TRUE:
        clc                                ; Exit assert success
        rts

@false:
        lda #AXERRAssert                    ; Exit assert fail
@AXIExit:
        sec
        rts

; ************************************************************************************************
;
;                               .if <exp>
;
; ************************************************************************************************

AXIFCmd:  ;; {.if}

; Are we already in a conditional?
        bit condasm_flags
        bmi @AXINestedCond              ; Taken if so...

        ldx AXOperandPos                ; Get operand, must be defined even on pass 1.
        jsr AXGet                       ; What follows?
        cmp #0
        beq @AXISyntax                  ; Taken if no expression (syntax error)

        jsr AXPass2Expression           ; get value
        bcs @AXIExit                    ; Taken if error, C is set and A-reg has error code

; Check for garbage on line after expression:
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        bne @AXISyntax                  ; Taken if it is NOT nothing - i.e. garbage on line (syntax err
        
        lda AXLeft
        ora AXLeft+1                    ; OR the LSB and MSB, if it is still zero, the expression is FALSE.
        beq @false

; Non-zero expression is TRUE:

        lda #CONDASM_ENABLED               ; Condasm ON and skip is OFF
        sta condasm_flags
        bra @AXIExit_ok
@false:

        lda #CONDASM_ENABLED|CONDASM_SKIP   ; Condasm ON and skip is ON
        sta condasm_flags
        bra @AXIExit_ok

@AXIExit_ok:
        clc
@AXIExit:
        rts
      
@AXINestedCond:
        lda #AXERRCondNested
        bra @AXIExit_err

@AXISyntax:
        lda #AXERRSyntax
@AXIExit_err:
        sec
        rts

; ************************************************************************************************
;
;                               .ifdef <identifer>
;                               .ifndef <identifer>
;
; ************************************************************************************************

AXIFDEFCmd:  ;; {.ifdef}

        stz Temp0               ; 0 = ifdef, 1 = ifndef
        jmp AXIFDEF_common


AXIFNDEFCmd:  ;; {.ifndef}

        stz Temp0               ; 0 = ifdef, 1 = ifndef
        dec Temp0               ; IFNDEF...
        jmp AXIFDEF_common

; ************************************************************************************************
;
;                               IFDEF common code
; Called from ifdef and ifndef
; Inputs: Temp0 -  0 = ifdef, 1 = ifndef
;
; ************************************************************************************************

AXIFDEF_common:

; Are we already in a conditional?
        bit condasm_flags
        bmi @AXINestedCond              ; Taken if so...

        ldx AXOperandPos                ; Get operand, must be defined even on pass 1.
        jsr AXGet                       ; What follows?
        cmp #0
        beq @AXISyntax                  ; Taken if no expression (syntax error)

        jsr AXExtractIdentifier         ; Get an identifier 
        bcs @AXISyntax                  ; Taken if identifier NOT found (syntax error)

; Identifier found, but first check for garbage on line after the identifier:
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        bne @AXISyntax                  ; Taken if it is NOT nothing - i.e. garbage on line (syntax error)

; We found an identifier on the line, now see if it exists in the symbol table:
        ldx #0                          ; XY points to symbol table base, AXLabelBuffer contains identifier
        ldy AXIBase
        jsr AXIFind     ; Does it exist?
        bcs @notfound   ; Taken if not

;----------------------------
; Identifier exists
;----------------------------

        bit Temp0               ; Are we ifdef or ifndef?
        bmi  @ifndef0           ; Taken if ifndef

; This is ifdef, found, so clear SKIP:

        lda #CONDASM_ENABLED               ; IFDEF, condasm ON and skip is OFF
        sta condasm_flags
        bra @AXIExit_ok

; This is ifndef, found, so set SKIP:
@ifndef0:
        lda #CONDASM_ENABLED|CONDASM_SKIP   ; IFNDEF, condasm ON and skip is ON
        sta condasm_flags
        bra @AXIExit_ok

;----------------------------
; Identifier does NOT exist
;----------------------------
@notfound:
        bit Temp0               ; Are we ifdef or ifndef?
        bmi  @ifndef1           ; Taken if ifndef
;
; This is ifdef, not found, so set SKIP:
        lda #CONDASM_ENABLED|CONDASM_SKIP   ; Condasm ON and skip is ON
        sta condasm_flags
        bra @AXIExit_ok

; This is ifndef, not found, so clear SKIP:
@ifndef1:
        lda #CONDASM_ENABLED               ; IFNDEF, condasm ON and skip is OFF
        sta condasm_flags
        bra @AXIExit_ok

@AXIExit_ok:
        clc
@AXIExit:
        rts
      
@AXINestedCond:
        lda #AXERRCondNested
        bra @AXIExit_err

@AXISyntax:
        lda #AXERRSyntax
@AXIExit_err:
        sec
        rts


; ************************************************************************************************
;
;                               .else
;
; ************************************************************************************************

AXELSECmd:  ;; {.else}

; Make sure we ARE in a conditional:
        bit condasm_flags       ; Are we in a conditional block (as required)?
        bmi @Cond_ok            ; Taken if so (condasm_flags b7 is set)
        lda #AXERRCondNoIf      ; Error .else without .if
        bra @AXIExit_err

@Cond_ok:
; Make sure we are NOT already in an .else block:
        lda condasm_flags
        and #CONDASM_ELSE       ; Is ELSE already active?
        beq @ELSE_ok            ; Taken if we are NOT already in an .else block

        lda #AXERRCondNested    ; Nested conditional (.else within an .else block)
        bra @AXIExit_err

; There should be nothing on the line after .else:

@ELSE_ok:
        ldx AXOperandPos
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        beq @line_empty                 ; Taken if it is nothing (as expected)
        lda #AXERRSyntax                ; Garbage on line
        bra @AXIExit_err

@line_empty:
; For .else we just invert the value of CONDASM_SKIP:
        lda condasm_flags
        ora #CONDASM_ELSE       ; Set the CONDASM_ELSE flag
        sta condasm_flags
        eor #CONDASM_SKIP       ; This should just invert the one bit
        sta condasm_flags
        clc
        rts

@AXIElseNoIf:

@AXIExit_err:
        sec
        rts

; ************************************************************************************************
;
;                               .else
;
; ************************************************************************************************

AXENDIFCmd:  ;; {.endif}

; Make sure we ARE in a conditional:
        bit condasm_flags       ; Are we in a conditional block (as required)?
        bmi @Cond_ok            ; Taken if so (condasm_flags b7 is set)
        lda #AXERRCondNoIf      ; Error .else without .if
        bra @AXIExit_err

@Cond_ok:
; Make sure there is nothing on the line after ".endif":
        ldx AXOperandPos
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        beq @line_empty                 ; Taken if it is nothing (as expected)
        lda #AXERRSyntax                ; Garbage on line
        bra @AXIExit_err

; This is the body of ".endif":
@line_empty:
        stz condasm_flags       ; Condasm OFF
        clc
        rts

@AXIExit_err:
        sec
        rts


        


; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       term.asm
;       Purpose:    Evaluate term.
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
;                               Evaluate term at Buffer,X.
;
;         Return CS on error, A is error code. CC if successful. Result goes into AXLeft
;
;       Terms can be :  decimal $hexadecimal %binary
;                       'x' character code.
;                       - negation 
;                       * program counter at start of instruction.
;                       label.address @label.page
;                       <lower.byte >upper.byte
;                       (expression)
;
; ************************************************************************************************

AXTerm: jsr     AXGet
        ;
        stz     AXLeft+2                    ; clear the undefined flag & value
        stz     AXLeft
        stz     AXLeft+1
        stz     AXLeft_byte3                ; Limited support for 3-byte constants (long)
        ;
        lda     AXBuffer,x                  ; get first character
        ldy     #10                         ; default decimal if digit
        jsr     AXIsNumeric                 ; if digit numeric , then constant.
        bcc     @AXIsConstant
        ; 
        inx                                 ; temporarily consume base modifier
        ldy     #16                         ; hex check.
        cmp     #'$'
        beq     @AXIsConstant
        ldy     #2                          ; binary check
        cmp     #'%'
        bne     @AXNotConstant

; ================================================================================================
;
;                               Constant at buffer,X. Base is in Y.
;
; ================================================================================================

@AXIsConstant:      
        stz     AXDigitCount                ; clear count of digits
        sty     AXBase                      ; save base.
@AXConstantLoop:
        lda     AXBuffer,x                  ; get the next character of the constant.       
        jsr     AXIsAlphaNumeric            ; must be 0-9A-Z
        bcs     @AXConstantDone             ; no, then end of constant.
        ;
        cmp     #'9'+1                      ; shift A-Z so they follow 0-9.
        bcc     @AXNotAlpha
        sbc     #7
@AXNotAlpha:
        sec                                 ; make it a digit 0..15
        sbc     #'0'        
        cmp     AXBase                      ; if higher than the base, then end of constant
        bcs     @AXConstantDone
        ;
        inx                                 ; consume as legal.
        inc     AXDigitCount                ; bump consumed count.
        pha                                 ; save the new digit.
        jsr     @AXMultiplyBase             ; multiply left by base.       
        pla                                 ; add new digit
        clc
        adc     AXLeft
        sta     AXLeft
        bcc     @AXConstantLoop
        inc     AXLeft+1
        bra     @AXConstantLoop
        ;
        ;       Reached an invalid constant.
        ;
@AXConstantDone:
        clc
        lda     AXDigitCount                ; exit okay if a digit received
        bne     @AXCExit
        sec                                 ; return error-syntax
        lda     #AXERRSyntax 
@AXCExit:
        rts     

; ================================================================================================
;
;                                   Parenthesis expression
;
; ================================================================================================

@AXParenthesis:
        jsr     AXExpression                ; body of parenthesis expression.
        bcs     @AXPExit                    ; error ?
@AXFindParent:
        jsr     AXGet                       ; next non-space
        inx                                 ; consume
        cmp     #')'
        clc
        beq     @AXPExit
        lda     #AXERRSyntax                ; failed
        sec
@AXPExit:
        rts

; ================================================================================================
;
;       Handle non constants. Not $x %x or decimal. First character in A, already consumed.
;       
; ================================================================================================

@AXNotConstant:
        cmp     #'-'                        ; check for negation.
        beq     @AXNegate
        cmp     #'<'                        ; low byte
        beq     @AXLowByte
        cmp     #'>'                        ; high byte
        beq     @AXHighByte
        cmp     #'*'                        ; start of instruction
        beq     @AXProgramCounter
        cmp     #$27                        ; character code (single  quote: ')
        beq     @AXCharacter        
        cmp     #'?'                        ; label page (note: feature changed from @ to ?)
        beq     @AXLabelPage
        cmp     #'('                        ; parenthesis
        beq     @AXParenthesis
        jsr     AXIsIdentifierHead          ; identifier start character
        bcs     @AXCFail
        dex                                 ; back to first character.
        jsr     AXEvaluateLabel             ; consume and evaluate a label.
        rts                                 

; ================================================================================================
;
;                                       Character code.
;
; ================================================================================================

@AXCharacter:
        lda     AXBuffer,x                  ; get the character code.
        beq     @AXCFail                    ; can't be EOS.
        sta     AXLeft
        lda     AXBuffer+1,x                ; get the character after and consume both
        inx
        inx
        cmp     #$27                        ; okay if ' (single quote)
        clc
        beq     @AXNExit
@AXCFail:                                   ; fail with syntax error.
        sec
        lda     #AXERRSyntax
        rts 

; ================================================================================================
;
;                                       Label page ?label
;   
; ================================================================================================

@AXLabelPage:       
        jsr     AXEvaluateLabel             ; consume and evaluate a label.
        bcs     @AXLPExit                   ; something failed, probably no label.
        lda     AXEvaluatePage              ; copy page #
        sta     AXLeft
        stz     AXLeft+1
        clc
@AXLPExit:
        rts     

; ================================================================================================
;
;                                     PC at instruction start
;
; ================================================================================================

@AXProgramCounter:
        lda     AXProgramCounterStart
        sta     AXLeft      
        lda     AXProgramCounterStart+1
        sta     AXLeft+1
        clc
        rts

; ================================================================================================
;
;                       High low byte (processing does not affect carry)
;
; ================================================================================================

@AXHighByte:
        jsr     AXTerm
        bcs     @AXNExit
        lda     AXLeft+1
        sta     AXLeft
        stz     AXLeft+1        
        rts
        ;
@AXLowByte:
        jsr     AXTerm
        bcs     @AXNExit
        stz     AXLeft+1
        rts

; ================================================================================================
;
;                                       Negate
;
; ================================================================================================

@AXNegate:
        jsr     AXTerm                      ; get term
        bcs     @AXNExit
        sec
        lda     #0
        sbc     AXLeft
        sta     AXLeft
        lda     #0
        sbc     AXLeft+1
        sta     AXLeft+1
        clc                                 ; success.
@AXNExit:       
        rts

; ================================================================================================
;
;                   Multiply the AXLeft value by the base (supports 2,10,16)
;
; ================================================================================================

@AXMultiplyBase:
        cpy     #2                          ; if binary then x2 exit.
        beq     @AXMDouble
        cpy     #16                         ; if hexadecimal then x16
        beq     @AXMMultiply16
        ;
        lda     AXLeft_byte3                ; keep original value to add back...
        pha
        lda     AXLeft+1
        pha
        lda     AXLeft 
        jsr     @AXMDouble                  ; x 2
        jsr     @AXMDouble                  ; x 4       
        clc
        adc     AXLeft                      ; add original value, e.g. x 5
        sta     AXLeft
        pla
        adc     AXLeft+1
        sta     AXLeft+1
        pla
        adc     AXLeft_byte3
        sta     AXLeft_byte3
        bra     @AXMDouble                  ; double to x10

@AXMMultiply16:
        jsr     @AXMDouble                  ; x 2
        jsr     @AXMDouble                  ; x 4       
        jsr     @AXMDouble                  ; x 8, fall through to x 16
@AXMDouble:
        asl     AXLeft                      ; everyone does left.
        rol     AXLeft+1
        rol     AXLeft_byte3                ; *** 65C816 limited support for 3-byte constants (long)
@AXMExit:
        rts

; ************************************************************************************************
;
;                           Get next non space character from buffer
;
; ************************************************************************************************

AXGet:
        lda     AXBuffer,x                  
        inx
        cmp     #' '
        beq     AXGet
        dex
        cmp     #0
        rts

; ************************************************************************************************
;
;                                   Extract and evaluate label
;
; ************************************************************************************************

AXEvaluateLabel:
        jsr     AXExtractIdentifier         ; get a label. 
        bcs     @AXEExit                    ; we couldn't.

        phx                                 ; save current position

        ldx     #0                          ; create or find the value.
        ldy     AXIBase
        jsr     AXICreateFind       
        ;
        ldy     #AXID_DataLow               ; copy data
        jsr     AXIGet
        sta     AXLeft+0

        ldy     #AXID_DataHigh
        jsr     AXIGet
        sta     AXLeft+1

        ldy     #AXID_Flags                 ; just the undefined flag.
        jsr     AXIGet
        and     #$80
        sta     AXLeft+2

        lda     #AXID_DataAux               ; get bank page of label.
        jsr     AXIGet
        sta     AXEvaluatePage 

        plx                                 ; restore current position.
        clc

@AXEExit:
        rts     


        .segment "VARS"

AXDigitCount:                               ; number of digits in constant.
        .res   1
AXBase:                                     ; temporary for base.
        .res   1       



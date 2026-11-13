; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       petscii.asm
;       Purpose:    .petscii command (byte with possible text string encoded as PETSCII U/L)
;       Created:    11th March 2025
;       Original Author: Paul Robson (paul@robsons.org.uk)
;       Copied from "text.asm" and modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble .petscii command
;
; ************************************************************************************************

AXPETSCIICmd:  ;; {.petscii}

        ldx     AXOperandPos                ; get operand, must be defined even on pass 1.

@AXTLoop:
        jsr     AXGet                       ; is it a quoted string
        cmp     #'"'
        beq     @AXTText

        jsr     AXPass2Expression           ; get value
        bcs     @AXTExit

        lda     AXPass                      ; only check size on pass 2
        cmp     #2
        bne     @AXTNoCheck

        lda     AXLeft+1
        beq     @AXTNoCheck

        lda     #AXERRSize                  ; not a byte.
        sec
        rts

@AXTNoCheck:
        lda     AXLeft                      ; output the byte.

;Check for ASCII "A"-"Z"
        cmp     #ASCII_A
        bcc     @WB1                        ; Taken if char is < "A"
        cmp     #ASCII_Z+1
        bcs     @Check_LC1                   ; Taken if char is >= "Z"+1
; Char is "A"-"Z" 
        ora     #$20                        ; "add" $20 ASCII US -> PETSCII_UL UC
        bra     @WB1
; Check for ASCII "a"-"z"
@Check_LC1:
        cmp     #ASCII_a
        bcc     @WB1
        cmp     #ASCII_z+1
        bcs     @WB1
; Char is "a"-"z"
        and     #$DF            ; "subtract" $20 ASCII US -> PETSCII_UL UC
@WB1:
        jsr     AXWriteByte
        bcs     @AXTExit                    ; A-reg already has error code from AXWriteByte
@AXTNext:
        jsr     AXGet                       ; get next
        inx
        cmp     #','
        beq     @AXTLoop
        cmp     #0
        bne     @AXTSyntax
@AXTOkay:       
        clc
        rts

@AXTText:
        jsr     AXTGetTextString            ; get text string to buffer.
        bcs     @AXTExit                    ; failed
        ldy     #0
@AXTOut:
        lda     AXTextParameter,y           ; get character
        beq     @AXTNext                    ; end of string, do next parameter

;Check for ASCII "A"-"Z"
        cmp     #ASCII_A
        bcc     @WB2                        ; Taken if char is < "A"
        cmp     #ASCII_Z+1
        bcs     @Check_LC2                   ; Taken if char is >= "Z"+1
; Char is "A"-"Z" 
        ora     #$20                        ; "add" $20 ASCII US -> PETSCII_UL UC
        bra     @WB2
; Check for ASCII "a"-"z"
@Check_LC2:
        cmp     #ASCII_a
        bcc     @WB2
        cmp     #ASCII_z+1
        bcs     @WB2
; Char is "a"-"z"
        and     #$DF            ; "subtract" $20 ASCII US -> PETSCII_UL UC

@WB2:
        jsr     AXWriteByte
        bcs     @AXTExit                    ; A-reg already has error code from AXWriteByte
        iny                                 ; keep going.
        bra     @AXTOut
@AXTSyntax:
        lda     #AXERRSyntax
        sec
@AXTExit:       
        rts


        


; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       ctypes.asm
;       Purpose:    Simple character functions
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
;                                   Convert lower to upper case
;
; ************************************************************************************************

AXConvertUpper:
        cmp     #ASCII_a
        bcc     @AXCNotUpper
        cmp     #ASCII_z+1
        bcs     @AXCNotUpper
        eor     #$20
@AXCNotUpper:
        rts     

; ************************************************************************************************
;
;                       Check U/C alphabetic (return CC = True, CS = False)
;
; ************************************************************************************************

AXIsAlpha:
        cmp     #ASCII_A
        bcc     @AXNotAlpha
        cmp     #ASCII_Z+1
        bcs     @AXNotAlpha
        rts
@AXNotAlpha:
        sec
        rts     

; ************************************************************************************************
;
;                       Check Decimal Digit (return CC = True, CS = False)
;
; ************************************************************************************************

AXIsNumeric:
        cmp     #'0'
        bcc     @AXNotDigit
        cmp     #'9'+1
        bcs     @AXNotDigit
        rts
@AXNotDigit:
        sec
        rts     

; ************************************************************************************************
;
;                      Check U/C alphanumeric (return CC = True, CS = False)
;
; ************************************************************************************************

AXIsAlphaNumeric:
        jsr     AXIsAlpha                   ; if alpha then exit with yes
        bcs     AXIsNumeric                 ; no, depends on is numeric
        rts

; ************************************************************************************************
;
;                     Is an identifier HEAD character A-Z _ @ .
;
; ************************************************************************************************

AXIsIdentifierHead:
        jsr     AXIsAlpha
        bcs     AXCheckIdentifierMisc
        rts

; ************************************************************************************************
;
;         Check for non alphanumeric character allowed in identifier, currently _ and . and @
;
; ************************************************************************************************

AXCheckIdentifierMisc:       
        cmp     #ASCII_UNDERSCORE
        beq     @AXIsIdentB
        cmp     #'@'
        beq     @AXIsIdentB
        cmp     #'.'
        beq     @AXIsIdentB
        sec
        rts
@AXIsIdentB:
        clc
        rts

; ************************************************************************************************
;
;                            Is an identifier body character A-Z 0-9 _ .
;
; ************************************************************************************************
        
AXIsIdentifierBody:
        jsr     AXIsAlphaNumeric
        bcs     AXCheckIdentifierMisc
        rts





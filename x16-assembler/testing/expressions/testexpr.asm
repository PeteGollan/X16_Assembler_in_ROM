; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      testexpr.asm
;       Purpose :   Expression test harness
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .section as16code

TestExpressions:

        lda     #TestData >> 8              ; zTemp points to test data
        sta     zTemp+1
        lda     #TestData & $FF
        sta     zTemp
_TestLoop:
        lda     (zTemp)                     ; check done
        bne     _TestNotEnd
        jmp     $FFFF
_TestNotEnd:
        ldy     #1                          ; copy test text to buffer
_Copy1:     
        lda     (zTemp),y
        jsr     AXConvertUpper
        sta     AXBuffer-1,y
        iny
        cmp     #0
        bne     _Copy1

        phy                                 ; evaluate, check error
        ldx     #0
        jsr     AXExpression
        bcs     _ErrorOccurred
        ply

        lda     (zTemp),y                   ; check result
        cmp     AXLeft 
        bne     _ResultWrong
        iny
        lda     (zTemp),y
        cmp     AXLeft+1
        bne     _ResultWrong

        clc                                 ; next test
        lda     (zTemp)
        adc     zTemp
        sta     zTemp
        bcc     _TestLoop
        inc     zTemp+1
        bra     _TestLoop

_ResultWrong:                               ; answer wrong
        ldx     zTemp
        ldy     zTemp+1
        lda     #$EE
        .byte   $DB
        jmp     _ResultWrong

_ErrorOccurred:                             ; error in evaluation.
        ldx     #$EE
        ldy     #$EE
        .byte   $DB
        jmp     _ErrorOccurred

TestData:   
        .include "../../build/testdata.inc"
        .byte   0

        .send as16code

        .section as16zeropage
zTemp:  .fill   2
        .send as16zeropage


; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      main.asm
;       Purpose :   Main Program (wrapper for testing with api in api directory)
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;                               Set up the three required sections
;
; ************************************************************************************************

        * = CODEADDR
        .dsection as16code

        * = STORAGE
        .dsection as16storage

        * = ZEROPAGE
        .dsection as16zeropage

; ************************************************************************************************
;
;                                       Test code boot
;
; ************************************************************************************************

        .section as16code
        jmp     Start

        .include "../../build/libassembler.asm"

Start:  
        ;
        ;       This tests expressions
        ;
        .if     TESTING==1
        ldx     #<DummyAPI          ; set up dummy so reset works.
        ldy     #>DummyAPI
        stx     AXAPI                       
        sty     AXAPI+1
        jsr     AXIReset
        jsr     TestExpressions

DummyAPI:                           ; just enough to make it work !!
        lda     #$90
        ldy     #$9F
        clc
        rts     

        .endif
        ;
        ;       This is what is normally run, assembles code as received via API.
        ;
        .if     (TESTING==2)||(TESTING==3)  
        jsr     ClearMemory
        ldx     #SampleAPIHandler & $FF
        ldy     #SampleAPIHandler >> 8
        jsr     AXAssemble
        .if     TESTING==3
        jmp     $FFFF
        .endif
        rts
        .endif

ClearMemory:
        lda     #$8F
        sta     AXTemp0+1
        stz     AXTemp0
_CMLoop:lda     #$FF
        sta     (AXTemp0)
        inc     AXTemp0
        bne     _CMLoop
        dec     AXTemp0+1       
        bmi     _CMLoop
        rts

        .send as16code

        .if     TESTING==1
        .include "testexpr.asm"
        .endif
        .if     (TESTING==2)||(TESTING==3)  
        .include "../../source/api/x16/api.asm"


        .endif


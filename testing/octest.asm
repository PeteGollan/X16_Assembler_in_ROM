;--------------------------------------------------------------------------
; octest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; August 2026
; Ottawa, Canada
;
; Test operators and conditionals
;
; Tests that cause errors are commented out. Uncoment to test.
; Review the listing file to check conditional block assembly.
;
;----------------------------------------------------------------------------
; IF THE OTHER TEXT IS SCRAMBLED, SWITCH TO ISO MODE:
;   CTRL-E AND LEFT ARROW UNTIL IT SAYS "ISO".
;----------------------------------------------------------------------------

; Assemble direct to memory:
    .direct
    .list "octest.lst"  ; Need listing to see the results.

;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
    CHROUT  = $FFD2 ; Character out - A-reg is destroyed

;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
    CR   = $0D    ; AKA \r - New line character in Commodore and CX16 PETSCII


    .rambank 5
    * = $A000

;---------------------------------------------
; MAIN
;---------------------------------------------


main:

DEBUG=1

foo  = $13              ; foo = $13

; Operation followed by expected value
; All operations are done on 16 bits.

foo2 .word -foo         
     .word $FFED    ; unary '-' does two's complement

foo3 .word foo * 2      ; foo3 = $26
     .word $26

foo4 .word foo & $0F    ; foo4 = $03
     .word $03

foo5 .word foo | $F0    ; foo5 = $F3
     .word $F3

foo6 .word foo = $13    ; TRUE ($FFFF)
     .word $FFFF

foo7 .word foo = $11    ; FALSE ($0000)
     .word $0000



; Assert tests:

    .assert foo < $50   ; TRUE
    
;    .assert foo=$5      ; FALSE


; Conditional assembly tests:

    
    .if foo=$13     ; TRUE
    lda #$01
    .else
    lda #$02
    .endif          ; It is OK to have a comment


    .if foo > $50   ; FALSE
    lda #$11
    .else           ; Comment on else is OK
    lda #$12
    .endif


; Test error cases (uncomment to test):


; Case 1 - nested .if:
;    .if foo=$13
;    .if foo=$13     ; Error - nested .if
;    .else
;    .endif

; Case 2 - .else without .if:
;    .else           ; Error - no .if

; Case 3 - .endif with no .if
;    .endif          ; error - no .if


; Case 4 - nested .else
;    .if foo=$13
;    .else
;    .else           ; Error - nested .else
;    .endif

; These cases are "garbage on line".
; We want to catch these typos.

; Case 5 - .else with garbage on line
;    .if foo=$13     ; TRUE
;    .else lda       ; Error - "lda" shouldn't be here
;    .endif

; Case 6 - .endif with garbage on line
;    .if foo=$13     ; TRUE
;    .else
;    .endif nop  ; Error - "nop" shouldn't be here


; Case 7 - .ifdef with existing identifier:
    .ifdef foo      ; DEFINED
    lda #$A7        ; Assembled
    .else
    lda #$F7        ; Skipped
    .endif

; Case 8 - .ifdef with non-existing identifer:

    .ifdef W65816   ; NOT DEFINED
    lda #$F8        ; Skipped
    .else
    lda #$A8        ; Assembled
    .endif

; Case 9 - .ifdef with no identifier
;    .ifdef           ; SYNTAX ERROR
;    lda #$A9
;    .endif

; Case 10 - .ifdef with garbage on the line:

;    .ifdef foo lda #5   ; SYNTAX ERROR
;    .endif


; Case 11 - .ifndef with existing identifier:
    .ifndef foo     ; DEFINED
    lda #$FB        ; Skipped
    .else
    lda #$AB        ; Assembmbled
    .endif

; Case 12 - .ifndef with non-existing identifer:

    .ifndef W65816  ; NOT DEFINED
    lda #$AC         ; Assembled
    .else
    lda #$FC        ; SKipped
    .endif

; Case 13 - .ifndef with no identifier
;    .ifndef           ; SYNTAX ERROR
;    .endif

; Case 14 - .ifndef with garbage on the line:
;    .ifndef foo lda #5   ; SYNTAX ERROR
;    .endif



    rts


    



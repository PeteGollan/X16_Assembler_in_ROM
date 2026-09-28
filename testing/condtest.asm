;--------------------------------------------------------------------------
; condtest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; September 2026
; Ottawa, Canada
;
; Test conditionals
;----------------------------------------------------------------------------

; Assemble direct to memory:
    .direct
    .list "condtest.lst"  ; Need listing to see the results.

;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
    CHROUT  = $FFD2 ; Character out - A-reg is destroyed

;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
    CR   = $0D    ; AKA \r - New line character in Commodore and CX16 PETSCII

    foo = $13

    * = $1000


    lda #$00


; Assert tests:

    .assert foo < $50   ; TRUE
    
;    .assert foo=$5      ; FALSE

    .assert foo     ; TRUE (foo is non-zero)


; Conditional assembly tests:

 
    .if foo=$13     ; TRUE
    lda #$01
    .else
    lda #$A1        ; This should skip
    .endif          ; It is OK to have a comment

   
    .if foo > $50   ; FALSE
    lda #$02        ; This should skip
    lda #$03        ; This should also skip
    .else
    lda #$A2        ; This should be assembled
    lda #$A3        ; This should also be assembled

    .endif


    .ifdef foo      ; TRUE
    lda #$A4        ; This should be assembled
    .else
    lda #$04        ; This should skip
    .endif

    .ifndef foo      ; FALSE
    lda #$05        ; This should skip
    .else
    lda #$A5        ; This should be assembled
    .endif

    rts


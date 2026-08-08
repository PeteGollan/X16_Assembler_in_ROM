;--------------------------------------------------------------------------
; labeltest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; August 2026
; Ottawa, Canada
;
; Test labels
;----------------------------------------------------------------------------

; Assemble direct to memory:
    .direct

    .list "labeltest.lst"
;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
    CHROUT  = $FFD2 ; Character out - A-reg is destroyed
    foo = $12

;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
    CR   = $0D    ; AKA \r - New line character in Commodore and CX16 PETSCII

    ab.cd = $5a
    ab_cd = $a5
    ab@cd = $99

    .macro boo
        nop
    .endm

    leftboo .macro
        nop
    .endm

    * = $22
;    zp0 .fill 1
;    zp1 .fill 2

    * = $1000

;---------------------------------------------
; MAIN
;---------------------------------------------

main:
    lda #ab_cd
    ldx #ab.cd
    ldy #ab@cd

    lda #'*'
    jsr CHROUT
    lda #CR
    jsr CHROUT

    boo             ; macro invocation is ok
    leftboo         ; This is also OK

;    alabel          ; *** ERROR (not in 1st col, no colon, no assign)
    blabel:         ; VALID

    lsr             ; VALID
    lsr A           ; VALID
;    lrs A           ; *** ERROR        
;    lrs             ; *** ERROR
;    lad #'*'        ; *** ERROR
    rts


 woo = $99  ; VALID

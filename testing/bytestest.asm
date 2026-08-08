;--------------------------------------------------------------------------
; bytestest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; August 2026
; Ottawa, Canada
;
; Test bytes/byte.
;----------------------------------------------------------------------------

; Assemble direct to memory:

;    .direct

    * = $1000

;---------------------------------------------
; MAIN
;---------------------------------------------

main:

;    nop     ; 1 byte
    rts     ; 1 byte


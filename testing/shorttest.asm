;--------------------------------------------------------------------------
; shorttest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; July 2026
; Ottawa, Canada
;
; Test includes. To run: SYS $1000
;----------------------------------------------------------------------------

; Assemble direct to memory:

    .obj  "shorttest.prg"
;    .noaddr
    .list  "shorttest.lst"
;    .direct

; Zero page

    * = $22

foo: .fill 1


    * = $0801

;---------------------------------------------
; MAIN
;---------------------------------------------

; Contains 12 bytes:

    .binary "basic_header.bin"

main:

    lda #$5a    ; 2 
    sta foo     ; 2
    rts         ; 1

    .include "inc1.inc"
    

; 7 bytes
data:   .fill 7,$99

; 6 bytes
msg:     .petscii "abcde",$00

; Total:

;--------------------------------------------------------------------------
; inc1.inc
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; June 2026
; Ottawa, Canada
;
; An include file for inctest.asm.
;----------------------------------------------------------------------------

;    * = $c000

Inc1Msg:    .petscii "This is inc1.inc",$0D,$00

    .incbin "basic_header.bin"

    .include "inc2.inc"

    nop
;    fts ; error here
    rts

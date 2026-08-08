;--------------------------------------------------------------------------
; inc2.inc
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; June 2026
; Ottawa, Canada
;
; An include file for inctest.asm.
;----------------------------------------------------------------------------


Inc2Msg:     .petscii "This is inc2.inc",$0D,$00


    nop
;    foo
    rts

;    .incbin "basic_header.bin"
    .include "inc3.inc"
;    .include "inc4.inc"
;    .include "inc4abcdefghijklmnopqrstuvwxyz0123456789.inc"



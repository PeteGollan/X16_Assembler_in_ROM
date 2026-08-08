;--------------------------------------------------------------------------
; inctest.asm
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; June 2026
; Ottawa, Canada
;
; Test includes. To run: SYS $1000
;----------------------------------------------------------------------------

; Assemble direct to memory:

;    .obj  "inctest.prg"
    .list "inctest.lst"
    .direct

;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
CHROUT  = $FFD2 ; Character out - A-reg is destroyed

;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
CR   = $0D    ; AKA \r - New line character in Commodore and CX16 PETSCII
PETSCII_UL = $0E

;---------------------------------------------------------
; Zero Page - $0022-$007F are available
;---------------------------------------------------------
    * = $22
AuxsZP:          .fill 2    ; The auxs serial driver uses $22, so reserve it
MemPtr:          .fill 2    ; 2 bytes

    .macro PRSTR    ; string_addr
        ldx #<\1
        ldy #>\1
        jsr StrOut_XY
    .endm

    * = $0801

;---------------------------------------------
; MAIN
;---------------------------------------------

    .binary "basic_header.bin"

    .byte $ea,$ea,$ea,$ea,$ea,$ea,$60

HelloMsg:   .petscii PETSCII_UL,"INCTEST",CR,$00

main:
    PRSTR HelloMsg
    PRSTR Inc1Msg
;    PRSTR Inc2Msg
;    PRSTR ByeMsg
    rts

;HelloMsg:   .petscii PETSCII_UL,"INCTEST",CR,$00
;ByeMsg:     .petscii "End of run, have a nice day!",CR,CR,$00

    .include "inc1.inc"


;-----------------------------------------------------
; StrOut_XY:
;
; "C64/CX16" VERSION OF THIS FUNCTION THAT OPERATES ON A POINTER IN X,Y
;
;   Prior   : Prepare screen and character set   
;   On Entry: X,Y = pointer to zero-terminated string
;                   to write to the screen
;   On Exit:  C = 0 - success
;                 1 - error
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;-----------------------------------------------------
StrOut_XY:
        pha
        phx
        phy
        stx MemPtr
        sty MemPtr+1
        ldy #0
_next:
        lda (MemPtr),y
        beq _done
        jsr CHROUT
        bcs _done   ; error
        iny
        bne _next   ; falls through if y wraps around
_done:
        ply
        plx
        pla
        rts


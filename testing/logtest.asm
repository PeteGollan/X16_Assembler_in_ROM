;--------------------------------------------------------------------------
; logtest.asm - Test .logical/.endlogical
;
; A contrived example of using .logical/.endlogical to work with
; relocatable code. We can't use .rambank 1 with .direct because it
; is reserved by the assembler in both EDIT and command line.
; Creating the code as .logical and then copying it to its target
; on start up is a way to get around this limitation.
;
;----------------------------------------------------------------------------

    .direct
    .list "logtest.lst"

;-------------------
; ZP Bank Registers
;-------------------
RAM_BANK_REG = $00
ROM_BANK_REG = $01


;-------------------
; Constants
;-------------------
HOME_RAM_BANK = $01


;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
    CHROUT  = $FFD2 ; Character output to the screen


;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
    CR  = $0D   ; Puts the cursor on the next line.


;---------------------------------------------------------
; MAIN
;
;---------------------------------------------------------

    * = $1000

main:

    jsr CopyToBank      ; Copy our functon and data to our bank

    lda #HOME_RAM_BANK  ; Make sure we have our bank selected
    sta RAM_BANK_REG
    jsr PrHello
    rts

    .byte $FF,$FE,$FD


RelocStart:

    .logical $A000

PrHello:
    ldx #0
_next:    
    lda hello_msg,x
    beq _cont
    jsr CHROUT
    inx
    bne _next
    
_cont:
    rts

;    *=$B000     ; Error - can't change PC within .logical

fill_test:  .fill 16,$a5    ; Test of fill within .logical

    .align $10  ; Just a test of .align

hello_msg: .text "Hello CX16 from .logical code!",CR,CR,$00

    .byte $FF,$FE,$FD

    .endlogical

RelocEnd:


;----------------------------------
; Copy our function to RAM bank 1
;----------------------------------

CopyToBank:

    lda #HOME_RAM_BANK
    sta RAM_BANK_REG

    ldy #0
_next:
    lda RelocStart,y
    sta $A000,y
    iny
    cpy #RelocEnd-RelocStart
    bne _next

_cont:
    rts






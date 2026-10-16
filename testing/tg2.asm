;---------------------------------------------------------------------------------------------
; tg2
;
; Pete Wyspianski (AKA Gollan)
; October 2026
; Ottawa, Canada
;
; Code to test group 2 instructions on both the X16-Assembler and ca65

;---------------------------------------------------------
; CA65
;---------------------------------------------------------
;    .org $1000
;    .segment "ONCE"

;---------------------------------------------------------
; X16-ASM
;---------------------------------------------------------
    .direct
    .obj  "tg2x16.bin"
    .list "tg2.lst"
    * = $1000

;----------------------------------------------
; 65C02
;----------------------------------------------
;    .pc02
    .p65c02

    asl $1234
    asl $1234,x
    asl a
    asl $12
    asl $12,x

    bit $1234
    bit $1234,x
    bit $12
    bit $12,x
    bit #$12
;    bit #$1234  ; NOT SUPPORTED

    cpx $1234
    cpx $12
    cpx #$12
;    cpx #$1234  ; NOT SUPPORTED

    cpy $1234
    cpy $12
    cpy #$12
;    cpy #$1234  ; NOT SUPPORTED

    dec $1234
    dec a
    dec $1234,x
    dec $12
    dec $12,x

    inc $1234
    inc a
    inc $1234,x
    inc $12
    inc $12,x

;    jml ($1234)     ; 65C816 ONLY
    jmp $1234
;    jmp $123456     ; 65C816 ONLY
    jmp ($1234)
    jmp ($1234,x)
;    jsl $123456     ; 65C816 ONLY
    jsr $1234
;    jsr ($1234,x)   ; 65C816 ONLY

    ldx $1234
    ldx $1234,y
    ldx $12
    ldx $12,y
    ldx #$12
;    ldx #$1234      ; 65C816 16-bit ONLY

    ldy $1234
    ldy $1234,x
    ldy $12
    ldy $12,x
    ldy #$12
;    ldy #$1234      ; 65C816 16-bit ONLY

    lsr $1234
    lsr
    lsr a
    lsr $1234,x
    lsr $12
    lsr $12,x

    rol $1234
    rol
    rol a
    rol $1234,x
    rol $12
    rol $12,x

    ror $1234
    ror
    ror a
    ror $1234,x
    ror $12
    ror $12,x


    stx $1234
    stx $12
    stx $12,y

    sty $1234
    sty $12
    sty $12,x

    stz $1234
    stz $1234,x
    stz $12
    stz $12,x

    trb $1234
    trb $12

    tsb $1234
    tsb $12

;----------------------------------------------
; 65C816
;----------------------------------------------
;    .p816
    .p65c816

;----------------------------------------------
; 8-bit index register mode
;----------------------------------------------

    asl $1234
    asl $1234,x
    asl a
    asl $12
    asl $12,x

    bit $1234
    bit $1234,x
    bit $12
    bit $12,x

    cpx $12
    cpx $1234
    cpy #$12
;    cpy #$1234      ; 65C816 16-bit ONLY

    dec $1234
    dec a
    dec $1234,x
    dec $12
    dec $12,x

    inc $1234
    inc a
    inc $1234,x
    inc $12
    inc $12,x

    jml ($1234)     ; 65C816 ONLY
    jmp $1234
;    jmp $123456     ; 65C816 ONLY *** ca65 NOT WORKING ***
    jmp ($1234)
    jmp ($1234,x)
    jsl $123456     ; 65C816 ONLY
    jsr $1234
    jsr ($1234,x)   ; 65C816 ONLY

    ldx $1234
    ldx $1234,y
    ldx $12
    ldx $12,y
    ldx #$12
;    ldx #$1234      ; 65C816 16-bit ONLY

    ldy $1234
    ldy $1234,x
    ldy $12
    ldy $12,x
    ldy #$12
;    ldy #$1234      ; 65C816 16-bit ONLY

    lsr $1234
    lsr
    lsr a
    lsr $1234,x
    lsr $12
    lsr $12,x

    rol $1234
    rol
    rol a
    rol $1234,x
    rol $12
    rol $12,x

    ror $1234
    ror
    ror a
    ror $1234,x
    ror $12
    ror $12,x

    stx $1234
    stx $12
    stx $12,y

    sty $1234
    sty $12
    sty $12,x

    stz $1234
    stz $1234,x
    stz $12
    stz $12,x

    trb $1234
    trb $12

    tsb $1234
    tsb $12

;----------------------------------------------
; 16-bit index register mode
;----------------------------------------------
    .i16
    
        asl $1234
    asl $1234,x
    asl a
    asl $12
    asl $12,x

    bit $1234
    bit $1234,x
    bit $12
    bit $12,x

    cpx $12
    cpx $1234
    cpy #$12
    cpy #$1234

    dec $1234
    dec a
    dec $1234,x
    dec $12
    dec $12,x

    inc $1234
    inc a
    inc $1234,x
    inc $12
    inc $12,x

    jml ($1234)     ; 65C816 ONLY
    jmp $1234
;    jmp $123456     ; 65C816 ONLY *** ca65 NOT WORKING ***
    jmp ($1234)
    jmp ($1234,x)
    jsl $123456     ; 65C816 ONLY
    jsr $1234
    jsr ($1234,x)   ; 65C816 ONLY

    jsl $123456 ; SUPPORTED

    jsr $1234
;    jsr ($1234,x) - 65C816 ONLY *** ca65 NOT WORKING ***

    ldx $1234
    ldx $1234,y
    ldx $12
    ldx $12,y
    ldx #$12
    ldx #$1234

    ldy $1234
    ldy $1234,x
    ldy $12
    ldy $12,x
    ldy #$12
    ldy #$1234

    lsr $1234
    lsr
    lsr a
    lsr $1234,x
    lsr $12
    lsr $12,x

    rol $1234
    rol
    rol a
    rol $1234,x
    rol $12
    rol $12,x

    ror $1234
    ror
    ror a
    ror $1234,x
    ror $12
    ror $12,x

    stx $1234
    stx $12
    stx $12,y

    sty $1234
    sty $12
    sty $12,x

    stz $1234
    stz $1234,x
    stz $12
    stz $12,x

    trb $1234
    trb $12

    tsb $1234
    tsb $12

    brk
    brk $12
    cop
    cop $12
;    wdm
    wdm $12

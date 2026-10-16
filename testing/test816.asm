;---------------------------------------------------------------------------------------------
; test816.asm
;
; Pete Wyspianski (AKA Gollan)
; October 2026
; Ottawa, Canada
;
; Code to test 65C602 and 65C816 assembly on X16-ASM and ca65
;
; ca65 build command line:
;   cl65 -t cx16 -C cx16-asm.cfg -O --cpu 65816 --start-addr $1000 -l test816.lst -o test816.bin test816.asm
;
; x16-asm build command line:
;   asm"test816.asm"
;
; Selecting the assembler (ca65/x16-asm):
; (1) In the CA65/X16-ASM sections below, use comments to enable
;     the target assembler and disable the other assembler.
; (2) Search for ".p" and select the appropriate processor
;     pseudo ops for the assembler (two places):
;        .pwc02/.p816 for ca65
;        .65c02/.p65C816 for x16-asm
;
; ca65 produces "test816.bin and test816.lst"
; X16-Asm produces "test816_x16.bin and test816_x16.lst"
;
; Search "ca65" to see the instructions that are NOT supported.
;
;---------------------------------------------------------
; CA65
;---------------------------------------------------------
    .org $1000
    .segment "ONCE"
;---------------------------------------------------------
; X16-ASM
;---------------------------------------------------------
;    .direct
;    .list "test816_x16.lst"
;    .obj  "test816_x16.bin"
;    * = $1000

    .pwc02  ; ca65, but does not have bbr/bbs/smb/rmb instructions.
;    .p65C02

; 65C02 Group 1

    adc $1234           ; absolute
    adc $1234,x         ; absolute indexed x
    adc $1234,y         ; absolute indexed y
    adc #$12            ; immediate
    adc $12             ; dp
    adc ($12,x)         ; dp indexed x indirect
    adc $12,x           ; dp indexed x
    adc ($12)           ; dp indirect
    adc ($12),y         ; dp indirect indexed y

    and $1234           ; absolute
    and $1234,x         ; absolute indexed x
    and $1234,y         ; absolute indexed y
    and #$12            ; immediate
    and $12             ; dp
    and ($12,x)         ; dp indexed x indirect
    and $12,x           ; dp indexed x
    and ($12)           ; dp indirect
    and ($12),y         ; dp indirect indexed y

    cmp $1234           ; absolute
    cmp $1234,x         ; absolute indexed x
    cmp $1234,y         ; absolute indexed y
    cmp #$12            ; immediate
    cmp $12             ; dp
    cmp ($12,x)         ; dp indexed x indirect
    cmp $12,x           ; dp indexed x
    cmp ($12)           ; dp indirect
    cmp ($12),y         ; dp indirect indexed y

    eor $1234           ; absolute
    eor $1234,x         ; absolute indexed x
    eor $1234,y         ; absolute indexed y
    eor #$12            ; immediate
    eor $12             ; dp
    eor ($12,x)         ; dp indexed x indirect
    eor $12,x           ; dp indexed x
    eor ($12)           ; dp indirect
    eor ($12),y         ; dp indirect indexed y

    lda $1234           ; absolute
    lda $1234,x         ; absolute indexed x
    lda $1234,y         ; absolute indexed y
    lda #$12            ; immediate
    lda $12             ; dp
    lda ($12,x)         ; dp indexed x indirect
    lda $12,x           ; dp indexed x
    lda ($12)           ; dp indirect
    lda ($12),y         ; dp indirect indexed y

    ora $1234           ; absolute
    ora $1234,x         ; absolute indexed x
    ora $1234,y         ; absolute indexed y
    ora #$12            ; immediate
    ora $12             ; dp
    ora ($12,x)         ; dp indexed x indirect
    ora $12,x           ; dp indexed x
    ora ($12)           ; dp indirect
    ora ($12),y         ; dp indirect indexed y

    sbc $1234           ; absolute
    sbc $1234,x         ; absolute indexed x
    sbc $1234,y         ; absolute indexed y
    sbc #$12            ; immediate
    sbc $12             ; dp
    sbc ($12,x)         ; dp indexed x indirect
    sbc $12,x           ; dp indexed x
    sbc ($12)           ; dp indirect
    sbc ($12),y         ; dp indirect indexed y

    sta $1234           ; absolute
    sta $1234,x         ; absolute indexed x
    sta $1234,y         ; absolute indexed y
; sta immediate is not supported
    sta $12             ; dp
    sta ($12,x)         ; dp indexed x indirect
    sta $12,x           ; dp indexed x
    sta ($12)           ; dp indirect
    sta ($12),y         ; dp indirect indexed y

; 65C02 Group  2

    asl $1234           ; absolute
    asl a               ; accumulator
    asl $1234,x         ; absolute indexed x
    asl $12             ; dp
    asl $12,x           ; dp indexed x

    bit $1234           ; absolute
    bit $1234,x         ; absolute indexed x
    bit #$12            ; immediate
    bit $12             ; dp
    bit $12,x           ; dp indexed x

    brk                 ; imp
    brk #$12            ; imm - optional signature byte
    brk $12             ; dp - optional signature byte (alternate)

    cpx $1234           ; absolute
    cpx #$12            ; immediate
    cpx $12             ; dp

    cpy $1234           ; absolute
    cpy #$12            ; immediate
    cpy $12             ; dp

    dec $1234           ; absolute
    dec a               ; accumulator
    dec $1234,x         ; absolute indexed x
    dec $12             ; dp
    dec $12,x           ; dp indexed x

    inc $1234           ; absolute
    inc a               ; accumulator
    inc $1234,x         ; absolute indexed x
    inc $12             ; dp
    inc $12,x           ; dp indexed x

    jmp $1234           ; absolute
    jmp ($1232)         ; absolute indirect
    jmp ($1232,x)       ; absolute indexed indirect

    jsr $1234           ; absolute

    ldx $1234           ; absolute
    ldx $1234,y         ; absolute indexed y
    ldx $12             ; dp
    ldx $12,y           ; dp indexed y
    ldx #$12            ; immediate

    ldy $1234           ; absolute
    ldy $1234,x         ; absolute indexed x
    ldy $12             ; dp
    ldy $12,x           ; dp indexed x
    ldy #$12            ; immediate

    lsr $1234           ; absolute
    lsr a               ; accumulator
    lsr $1234,x         ; absolute indexed x
    lsr $12             ; dp
    lsr $12,x           ; dp indexed x

    rol $1234           ; absolute
    rol a               ; accumulator
    rol $1234,x         ; absolute indexed x
    rol $12             ; dp
    rol $12,x           ; dp indexed x

    ror $1234           ; absolute
    ror a               ; accumulator
    ror $1234,x         ; absolute indexed x
    ror $12             ; dp
    ror $12,x           ; dp indexed x

    stx $1234           ; absolute
    stx $12             ; dp
    stx $12,y           ; dp indexed y

    sty $1234           ; absolute
    sty $12             ; dp
    sty $12,x           ; dp indexed x

    stz $1234           ; absolute
    stz $1234,x         ; absolute indexed x
    stz $12             ; dp
    stz $12,x           ; dp indexed x

; 65C02 Group  3

_g3_start:
    bcc _g3_end         ; rel 
    bcs _g3_end         ; rel
    beq _g3_end         ; rel
    bmi _g3_end         ; rel
    bne _g3_end         ; rel
    bpl _g3_end         ; rel
    bra _g3_end         ; rel
    bvc _g3_end         ; rel
    bvs _g3_end         ; rel
    
    bcc _g3_start       ; rel 
    bcs _g3_start       ; rel
    beq _g3_start       ; rel
    bmi _g3_start       ; rel
    bne _g3_start       ; rel
    bpl _g3_start       ; rel
    bra _g3_start       ; rel
    bvc _g3_start       ; rel
    bvs _g3_start       ; rel
_g3_end:

; 65C02 Group  4

    clc                 ; imp/s
    cld                 ; imp/s
    cli                 ; imp/s
    clv                 ; imp/s
    dex                 ; imp/s
    dey                 ; imp/s
    inx                 ; imp/s
    iny                 ; imp/s
    nop                 ; imp/s
    pha                 ; imp/s
    php                 ; imp/s
    phx                 ; imp/s
    phy                 ; imp/s
    pla                 ; imp/s
    plp                 ; imp/s
    plx                 ; imp/s
    ply                 ; imp/s
    rti                 ; imp/s
    rts                 ; imp/s
    sec                 ; imp/s
    sed                 ; imp/s
    sei                 ; imp/s
    stp                 ; imp/s
    tax                 ; imp/s
    tay                 ; imp/s
    tsx                 ; imp/s
    txa                 ; imp/s
    tya                 ; imp/s
    wai                 ; imp/s

;--------------------------------
    .p816
;    .p65C816

; 65C816 Instructions NOT supported by ca65

;    jmp $123456         ; absolute long

; 65C816 Group 1

    adc $1234           ; absolute
    adc $1234,x         ; absolute indexed x
    adc $1234,y         ; absolute indexed y
    adc $123456         ; absolute long
    adc $123456,x       ; absolute long indexed x
    adc #$12            ; immediate
    adc $12             ; dp
    adc $12,s           ; stack rel 
    adc $12,x           ; dp indexed x
    adc ($12)           ; dp indirect
    adc [$12]           ; dp indirect long
    adc ($12,s),y       ; stack rel indirect indexed
    adc ($12,x)         ; dp indexed indirect
    adc ($12),y         ; dp indirect indexed
    adc [$12],y         ; dp indirect long indexed

    and $1234           ; absolute
    and $1234,x         ; absolute indexed x
    and $1234,y         ; absolute indexed y
    and $123456         ; absolute long
    and $123456,x       ; absolute long indexed x
    and #$12            ; immediate
    and $12             ; dp
    and $12,s           ; stack rel 
    and $12,x           ; dp indexed x
    and ($12)           ; dp indirect
    and [$12]           ; dp indirect long
    and ($12,s),y       ; stack rel indirect indexed
    and ($12,x)         ; dp indexed indirect
    and ($12),y         ; dp indirect indexed
    and [$12],y         ; dp indirect long indexed

    cmp $1234           ; absolute
    cmp $1234,x         ; absolute indexed x
    cmp $1234,y         ; absolute indexed y
    cmp $123456         ; absolute long
    cmp $123456,x       ; absolute long indexed x
    cmp #$12            ; immediate
    cmp $12             ; dp
    cmp $12,s           ; stack rel 
    cmp $12,x           ; dp indexed x
    cmp ($12)           ; dp indirect
    cmp [$12]           ; dp indirect long
    cmp ($12,s),y       ; stack rel indirect indexed
    cmp ($12,x)         ; dp indexed indirect
    cmp ($12),y         ; dp indirect indexed
    cmp [$12],y         ; dp indirect long indexed

    eor $1234           ; absolute
    eor $1234,x         ; absolute indexed x
    eor $1234,y         ; absolute indexed y
    eor $123456         ; absolute long
    eor $123456,x       ; absolute long indexed x
    eor #$12            ; immediate
    eor $12             ; dp
    eor $12,s           ; stack rel 
    eor $12,x           ; dp indexed x
    eor ($12)           ; dp indirect
    eor [$12]           ; dp indirect long
    eor ($12,s),y       ; stack rel indirect indexed
    eor ($12,x)         ; dp indexed indirect
    eor ($12),y         ; dp indirect indexed
    eor [$12],y         ; dp indirect long indexed

    lda $1234           ; absolute
    lda $1234,x         ; absolute indexed x
    lda $1234,y         ; absolute indexed y
    lda $123456         ; absolute long
    lda $123456,x       ; absolute long indexed x
    lda #$12            ; immediate
    lda $12             ; dp
    lda $12,s           ; stack rel 
    lda $12,x           ; dp indexed x
    lda ($12)           ; dp indirect
    lda [$12]           ; dp indirect long
    lda ($12,s),y       ; stack rel indirect indexed
    lda ($12,x)         ; dp indexed indirect
    lda ($12),y         ; dp indirect indexed
    lda [$12],y         ; dp indirect long indexed

    ora $1234           ; absolute
    ora $1234,x         ; absolute indexed x
    ora $1234,y         ; absolute indexed y
    ora $123456         ; absolute long
    ora $123456,x       ; absolute long indexed x
    ora #$12            ; immediate
    ora $12             ; dp
    ora $12,s           ; stack rel 
    ora $12,x           ; dp indexed x
    ora ($12)           ; dp indirect
    ora [$12]           ; dp indirect long
    ora ($12,s),y       ; stack rel indirect indexed
    ora ($12,x)         ; dp indexed indirect
    ora ($12),y         ; dp indirect indexed
    ora [$12],y         ; dp indirect long indexed

    sbc $1234           ; absolute
    sbc $1234,x         ; absolute indexed x
    sbc $1234,y         ; absolute indexed y
    sbc $123456         ; absolute long
    sbc $123456,x       ; absolute long indexed x
    sbc #$12            ; immediate
    sbc $12             ; dp
    sbc $12,s           ; stack rel 
    sbc $12,x           ; dp indexed x
    sbc ($12)           ; dp indirect
    sbc [$12]           ; dp indirect long
    sbc ($12,s),y       ; stack rel indirect indexed
    sbc ($12,x)         ; dp indexed indirect
    sbc ($12),y         ; dp indirect indexed
    sbc [$12],y         ; dp indirect long indexed

    sta $1234           ; absolute
    sta $1234,x         ; absolute indexed x
    sta $1234,y         ; absolute indexed y
    sta $123456         ; absolute long
    sta $123456,x       ; absolute long indexed x
; sta immediate is not supported
    sta $12             ; dp
    sta $12,s           ; stack rel 
    sta $12,x           ; dp indexed x
    sta ($12)           ; dp indirect
    sta [$12]           ; dp indirect long
    sta ($12,s),y       ; stack rel indirect indexed
    sta ($12,x)         ; dp indexed indirect
    sta ($12),y         ; dp indirect indexed
    sta [$12],y         ; dp indirect long indexed

; 65C816 Group  2

    asl $1234           ; absolute
    asl a               ; accumulator
    asl $1234,x         ; absolute indexed x
    asl $12             ; dp
    asl $12,x           ; dp indexed x

    bit $1234           ; absolute
    bit $1234,x         ; absolute indexed x
    bit #$12            ; immediate
    bit $12             ; dp
    bit $12,x           ; dp indexed x

    brk                 ; imp
    brk #$12            ; imm - optional signature byte
    brk $12             ; dp - optional signature byte (alternate)

    cop                 ; imp
    cop #$12            ; imm - optional signature byte
    cop $12             ; dp - optional signature byte (alternate)

    cpx $1234           ; absolute
    cpx #$12            ; immediate
    cpx $12             ; dp

    cpy $1234           ; absolute
    cpy #$12            ; immediate
    cpy $12             ; dp

    dec $1234           ; absolute
    dec a               ; accumulator
    dec $1234,x         ; absolute indexed x
    dec $12             ; dp
    dec $12,x           ; dp indexed x

    inc $1234           ; absolute
    inc a               ; accumulator
    inc $1234,x         ; absolute indexed x
    inc $12             ; dp
    inc $12,x           ; dp indexed x

    jml ($1232)         ; absolute indirect

    jmp $1234           ; absolute

    jmp ($1232)         ; absolute indirect
    jmp ($1232,x)       ; absolute indexed indirect

    jsl $123456         ; absolute long

    ldx $1234           ; absolute
    ldx $1234,y         ; absolute indexed y
    ldx $12             ; dp
    ldx $12,y           ; dp indexed y
    ldx #$12            ; immediate

    ldy $1234           ; absolute
    ldy $1234,x         ; absolute indexed x
    ldy $12             ; dp
    ldy $12,x           ; dp indexed x
    ldy #$12            ; immediate

    lsr $1234           ; absolute
    lsr a               ; accumulator
    lsr $1234,x         ; absolute indexed x
    lsr $12             ; dp
    lsr $12,x           ; dp indexed x

    mvn #$12,#$34       ; block move

    mvp #$12,#$34       ; block move

    rep #$12            ; immediate

    rol $1234           ; absolute
    rol a               ; accumulator
    rol $1234,x         ; absolute indexed x
    rol $12             ; dp
    rol $12,x           ; dp indexed x

    ror $1234           ; absolute
    ror a               ; accumulator
    ror $1234,x         ; absolute indexed x
    ror $12             ; dp
    ror $12,x           ; dp indexed x

    sep #$12            ; immediate

    stx $1234           ; absolute
    stx $12             ; dp
    stx $12,y           ; dp indexed y

    sty $1234           ; absolute
    sty $12             ; dp
    sty $12,x           ; dp indexed x

    stz $1234           ; absolute
    stz $1234,x         ; absolute indexed x
    stz $12             ; dp
    stz $12,x           ; dp indexed x

    wdm #$12            ; imm - mandatory signature byte
    wdm $12             ; dp - mandatory signature byte (alternate)

; 65C816 Group  3

_g3_start816:
    bcc _g3_end816      ; rel 
    bcs _g3_end816      ; rel
    beq _g3_end816      ; rel
    bmi _g3_end816      ; rel
    bne _g3_end816      ; rel
    bpl _g3_end816      ; rel
    bra _g3_end816      ; rel
    bvc _g3_end816      ; rel
    bvs _g3_end816      ; rel
    brl _g3_end816    ; rel long

    bcc _g3_start816    ; rel 
    bcs _g3_start816    ; rel
    beq _g3_start816    ; rel
    bmi _g3_start816    ; rel
    bne _g3_start816    ; rel
    bpl _g3_start816    ; rel
    bra _g3_start816    ; rel
    bvc _g3_start816    ; rel
    bvs _g3_start816    ; rel
    brl _g3_start816    ; rel long
_g3_end816:

; 65C816 Group  4
; All implied.

    clc
    cld
    cli
    clv
    dex
    dey
    inx
    iny
    nop
    pha
    phb
    phd
    phk
    php
    phx
    phy
    pla
    plb
    pld
    plp
    plx
    ply
    rti
    rtl
    rts
    sec
    sed
    sei
    stp
    tax
    tay
    tcd
    tcs
    tdc
    tsc
    tsx
    txa
    txy
    tya
    tyx
    wai
    xba
    xce

;--------------------------------
;
; 65C816 16-bit Immediate mode
; The pseduo ops are the same for both assemblers.

    .a16
    .i16

    rep #$12            ; immediate * always 8 bits
    sep #$12            ; immediate * always 8 bits
    brk #$12            ; immediate * always 8 bits
    cop #$12            ; immediate * always 8 bits
    wdm #$12            ; immediate * always 8 bits

; All 16-bit immediate:
    adc #$12
    adc #$1234
    and #$12  
    and #$1234
    cmp #$12  
    cmp #$1234
    eor #$12  
    eor #$1234
    lda #$12  
    lda #$1234
    ora #$12  
    ora #$1234
    sbc #$12  
    sbc #$1234
    bit #$12  
    bit #$1234
    cpx #$12  
    cpx #$1234
    cpy #$12  
    cpy #$1234
    ldx #$12  
    ldx #$1234
    ldy #$12  
    ldy #$1234



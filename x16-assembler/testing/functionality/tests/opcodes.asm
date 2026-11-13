; *******************************************************************************************
;
;			Test assembly of all standard 65C02 opcodes
;
; *******************************************************************************************

		* = $8000

		adc #$f3
		adc $4c
		adc $4c,x
		adc $89ab
		adc $89ab,x
		adc $89ab,y
		adc ($4c,x)
		adc ($4c),y
		adc ($4c)
		and #$f3
		and $4c
		and $4c,x
		and $89ab
		and $89ab,x
		and $89ab,y
		and ($4c,x)
		and ($4c),y
		and ($4c)
		asl a
		asl $4c
		asl $4c,x
		asl $89ab
		asl $89ab,x

		bcc *
		bcs *
		beq *
		bit #$f3
		bit $4c
		bit $4c,x
		bit $89ab
		bit $89ab,x
		bmi *
		bne *
		bpl *
		bra *
		brk
		bvc *
		bvs *
		clc
		cld
		cli
		clv
		cmp #$f3
		cmp $4c
		cmp $4c
		cmp $89ab
		cmp $89ab,x
		cmp $89ab,y
		cmp ($4c,x)
		cmp ($4c),y
		cmp ($4c)
		cpx #$f3
		cpx $4c
		cpx $89ab
		cpy #$f3
		cpy $4c
		cpy $89ab
		dec	a
		dec $4c
		dec $4c,x
		dec $89ab
		dec $89ab,x
		dex
		dey
		eor #$f3
		eor $4c
		eor $4c,x
		eor $89ab
		eor $89ab,x
		eor $89ab,y
		eor ($4c,x)
		eor ($4c),y
		eor ($4c)
		inc a
		inc $4c
		inc $4c,x
		inc $89ab
		inc $89ab,x
		inx
		iny
		jmp $89ab
		jmp ($89ab)
		jmp ($89ab,x)
		jsr $89ab
		lda #$f3
		lda $4c
		lda $4c,x
		lda $89ab
		lda $89ab,x
		lda $89ab,y
		lda ($4c,x)
		lda ($4c),y
		lda ($4c)
		ldx #$f3
		ldx $4c
		ldx $4c,y
		ldx $89ab
		ldx $89ab,y
		ldy #$f3
		ldy $4c
		ldy $4c,x
		ldy $89ab
		ldy $89ab,x
		lsr a
		lsr $4c
		lsr $4c,x
		lsr $89ab
		lsr $89ab,x
		nop
		ora #$f3
		ora $4c
		ora $4c,x
		ora $89ab
		ora $89ab,x
		ora $89ab,y
		ora ($4c,x)
		ora ($4c),y
		ora ($4c)
		pha
		phx
		phy
		pla
		plx
		ply
		rol a
		rol $4c
		rol $4c,x
		rol $89ab
		rol $89ab,x
		ror a
		ror $4c
		ror $4c,x
		ror $89ab
		ror $89ab,x
		rti
		rts
		sbc #$f3
		sbc $4c
		sbc $4c,x
		sbc $89ab
		sbc $89ab,x
		sbc $89ab,y
		sbc ($4c,x)
		sbc ($4c),y
		sbc ($4c)
		sec
		sed
		sei
		sta $4c
		sta $4c,x
		sta $89ab
		sta $89ab,x
		sta $89ab,y
		sta ($4c,x)
		sta ($4c),y
		sta ($4c)
		stx $4c
		stx $4c,y
		stx $89ab
		sty $4c
		sty $4c,x
		sty $89ab
		stz $4c
		stz $4c,x
		stz $89ab
		stz $89ab,x
		tax
		tay
		trb $4c
		trb $89ab
		tsb $4c
		tsb $89ab
		tsx
		txa
		txs
		tya



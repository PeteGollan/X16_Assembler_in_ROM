;--------------------------------------------------------------------------
; ad1 - X16 Assembler in ROM Demo #1
;
; Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; May 2026
; Ottawa, Canada
;
; Demonstration of the X16 Assembler. I encourage you to change this code
; and post your own demo!
;
; Main functions: demo_point, demo_drip
; Other functions: cls_reverse, Delay, short_delay
;----------------------------------------------------------------------------

; Assemble direct to memory:
    .direct
;	.list "ad1.lst"

;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
; CHRIN   = $FFCF ; Character in
CHROUT  = $FFD2 ; Character out - A-reg is destroyed
; GETIN   = $FFE4 ; get a character from the keyboard
PLOT    = $FFF0 ; Set/Get cursor XY coordinates
EXTAPI  = $FEAB
ENTROPY_GET = $FECF

DEFAULT_COLOUR_ADDR = $376


;---------------------------------------------------------
; VERA
;---------------------------------------------------------

VERA_ADDR_LO   = $9F20
VERA_ADDR_MID  = $9F21
VERA_ADDR_HI   = $9F22
VERA_DATA0     = $9F23
VERA_TEXT_BASE = $B000

;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------

BELL = $07    ; More like a beep
LF   = $0A	  ; AKA \n - New line in Linux AND X16-EDIT ISO mode
CR   = $0D	  ; AKA \r - New line character in Commodore and CX16 PETSCII
DQ   = $22    ; Double quote (stress-free way to include double quote in strings)

ISO_OFF = $8F   ; Also clears screen
PETSCII_U = $8E
PETSCII_UL = $0E

;---------------------------------------------------------
; PETSCII_UL Characters
;---------------------------------------------------------

BOX_VBAR  = $7D
BOX_HBAR  = $60
BOX_PLUS  = $7B
BOX_TL    = $B0
BOX_TR	  = $AE
BOX_BL	  = $AD
BOX_BR    = $BD

;---------------------------------------------------------
; Our Constants
;---------------------------------------------------------

TEXT_COL = 34   ; X-coord
TEXT_ROW = 29   ; Y-coord

;---------------------------------------------------------
; Zero Page - $0022-$007F are available
;---------------------------------------------------------
    * = $22
AuxsZP:          .fill 2    ; The auxs serial driver uses $22, so reserve it
MemPtr:          .fill 2    ; 2 bytes
MemPtr1:         .fill 2    ; 2 bytes
MemPtr2:         .fill 2    ; 2 bytes - used by higher-level  functions
Temp0:           .fill 1
Temp1:           .fill 1
resultLo:		 .fill 1
resultHi:		 .fill 1
count:			 .fill 2
vcolours:   	 .fill 1	; Vera bg+fg colours
paint_temp		 .fill 1	; used by paint

    * = $801

; BASIC stub that SYSes to $08d
    .byte $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

;---------------------------------------------
; MAIN
;---------------------------------------------

main:
    cld                 ; Just in case

; Prep the screen:

	lda #ISO_OFF		; FYI: positions the BASIC cursor at the top of the screen.
	jsr CHROUT
	lda #PETSCII_UL
	jsr CHROUT


; Now we can use VERA directly:

; Set the vcolours variable to the curent bg/fg value:
        ldy DEFAULT_COLOUR_ADDR
        sty vcolours

	jsr RNDInit

; Show hello message:

	ldx #0
	ldy #3
	jsr v_setxy

	ldx #<HelloStr0
    ldy #>HelloStr0
    jsr v_strout

	ldx #0
	ldy #5
	jsr v_setxy

	ldx #<HelloStr1
    ldy #>HelloStr1
    jsr v_strout

	ldx #120			; 4 second delay (for reading)
	jsr	Delay

;	jsr show_x16_box

; Call paint three times:
	lda #<$FFFF
	ldx #>$FFFF
	jsr demo_paint
	lda #<$FFFF
	ldx #>$FFFF
	jsr demo_paint
;	lda #<$FFFF
;	ldx #>$FFFF
;	jsr demo_paint

	ldx #90			; 3 second delay
	jsr Delay

	jsr show_x16_box

	ldx #90			; 3 second delay
	jsr	Delay

; Reverse screen clear, slowed down just a bit:
	jsr cls_reverse

	ldx #90			; 3 second delay
	jsr	Delay

; Call drip twice. This seems OK.
	jsr demo_drip
	jsr demo_drip

	ldx #90			; 3 second delay
	jsr	Delay

	jsr cls_reverse

	ldx #90			; 3 second delay
	jsr	Delay

	jsr show_x16_box

	ldx #90			; 3 second delay
	jsr	Delay

; Show exit message here:

	ldx #0
	ldy #5
	jsr v_setxy

	ldx #<HelloStr0		; Repeat the title.
    ldy #>HelloStr0
    jsr v_strout

	ldx #0
	ldy #7
	jsr v_setxy
	ldx #<ExitStr0
    ldy #>ExitStr0
    jsr v_strout

; Back to using the KERNAL, make a tidy exit to BASIC:

	ldy #0			    ; COLUMN (yes, it is confusing)
	ldx #(TEXT_ROW+5)   ; ROW
	clc					; Positions the BASIC cursor out of the way.
	jsr PLOT			; The "ready" prompt will be below our text.

	rts

;-------------------------------------------------------------------
; cls_reverse
;
;   A fun way to clear the screen starting at the the bottom right.
;   Includes a slight delay so the effect is visible.
;
;   Prior   : vcolours set
;   On Entry: n/a
;   On Exit:  All regs destroyed
;-------------------------------------------------------------------
cls_reverse:

; Sets the inter-character delay for the reverse cls. Mainly adjust sd_y_val.
	lda #$FF
	sta sd_a_val
	ldy #$02
	sty sd_y_val
	ldx #$01
	stx sd_x_val

	ldy #59		; Row
@prev_row:
	ldx #79		; Column
@prev_column:	
	jsr v_setxy	; Preserves X,Y
	lda #' '
	phy
	jsr v_chrout
	jsr short_delay			; Make the effect slightly visible...
	ply
	dex
	bpl @prev_column
	dey
	bpl @prev_row
	rts

;-------------------------------------------------------------------
; show_x16_box - Shows the X16 Assembler text in a box
;
;   Prior   : n/a
;   On Entry: n/a
;   On Exit:  All regs destroyed
;-------------------------------------------------------------------
show_x16_box:

	ldx #(TEXT_COL-1)
	ldy #(TEXT_ROW-1)
	jsr v_setxy

	ldx #<BoxTopStr
    ldy #>BoxTopStr
    jsr v_strout

	ldx #(TEXT_COL-1)
	ldy #TEXT_ROW
	jsr v_setxy

	ldx #<BoxAsmStr0
    ldy #>BoxAsmStr0
    jsr v_strout

	ldx #(TEXT_COL-1)
	ldy #(TEXT_ROW+1)
	jsr v_setxy

	ldx #<BoxAsmStr1
    ldy #>BoxAsmStr1
    jsr v_strout

	ldx #(TEXT_COL-1)
	ldy #(TEXT_ROW+2)
	jsr v_setxy

	ldx #<BoxBotStr
    ldy #>BoxBotStr
    jsr v_strout
	rts

;-------------------------------------------------------------------
; short_dealy - A fine-tuneable delay
;
; Based on:
; "Creating delays in a 6502 without RAM"
;  https://lateblt.livejournal.com/194836.html
;
;   Prior   : Set delay coefficients: sd_a_val, sd_y_val, sd_x_val
;   On Entry: n/a
;   On Exit:  All regs preserved
;
; Note: uses d_a_val, sd_y_val, sd_x_val
;-------------------------------------------------------------------
short_delay:
	pha
	phx
	phy

	ldx sd_x_val
@next_X:
	ldy sd_y_val
@next_Y:
	lda sd_a_val
@next_A:
	dec				; 2 cycles
	bne @next_A		; 2 cycles
    dey
    bne @next_y
    dex
    bne @next_x
	ply
	plx
	pla
	rts

sd_a_val	.fill 1
sd_x_val	.fill 1
sd_y_val	.fill 1

;-------------------------------------------------------------------
; demo_drip - Drip text down the screen.
;
;   Each drip is on a random column and has random length.
;   We do 39-79 drips (see the code for other ideas).
;   During a drip, characters are cycled in each position from
;	0-31 times.
;
;   Prior   : (optional) Call v_setxy to set the VERA "cursor"
;   On Entry: **** A,Y - character output count
;   On Exit:  All regs destroyed
;
; Note: uses paint_temp
;-------------------------------------------------------------------
demo_drip:

; Sets the inter-character delay for the drip. Mainly adjust sd_y_val.
	lda #$FF
	sta sd_a_val
	ldy #$02
	sty sd_y_val
	ldx #$01
	stx sd_x_val

	lda vcolours
	and #$F0		; Just keep BG
	sta paint_temp

; Other idea:
;	jsr RndColumn	; A-reg = 0-79
;	sta drip_num	; number of drips (0-79)

	jsr RndColumn	; A-reg = 0-79
	lsr				; A-reg = 0-39
	clc
	adc #40			; We will do 39-79 drips
	sta drip_num

@next_drip
	jsr RndColumn
	tax
	jsr RndRow		   ; Preserves x,y
	sta drip_length
	ldy #0				; Start row at zero (top of screen)

; Drip characters down the screen:
@next_drip_char:

; For each character, repeat 0-31 times:
	jsr rand8
	lsr					; 0-127
	lsr				    ; 0-63
	lsr				    ; 0-31
	sta drip_size
@do_drip:
	jsr V_setxy			; Preserves X,Y
	jsr RndChrIndex		; Get a VERA chara index 0-127  (preserves X,Y)
	sta VERA_DATA0      ; Write char index to VRAM
	jsr RndColour		; Random fg colour (preserves X,Y)
	ora paint_temp		; Splice bg+fg
	sta VERA_DATA0		; Write char colour to VRAM

	jsr short_delay

	dec drip_size
	bpl @do_drip		; Stay on the drip for 0-31 times

	dec drip_length
	bmi @drip_done		; Taken if done
	iny					; Next row
	bra @next_drip_char

@drip_done:
	dec drip_num		; Finished all the drips?
	bpl @next_drip		; Taken if not

	rts

drip_length:	.fill 1
drip_size		.fill 1		; OK, it is actully the number of character we write at a given drip location
drip_num		.fill 1	 	; How many drips to do

;-------------------------------------------------------------------
; demo_paint - Paint the screen with random character and colours
;
;   Prior   : (optional) Call v_setxy to set the VERA "cursor"
;   On Entry: A,Y - character output count
;   On Exit:  All regs destroyed
;
; Note: uses paint_temp
;-------------------------------------------------------------------
demo_paint:

	sta count
	stx count+1

	lda vcolours
	and #$F0		; Just keep BG
	sta paint_temp

@next:
	jsr DownCount16
	bcc @cont 
	jsr RndColumn
	tax
	jsr RndRow		   ; Preserves x,y
	tay
    jsr v_setxy         ; set cursor position

	jsr RndChrIndex		; Get a VERA chara index 0-127
	sta VERA_DATA0      ; Write char index to VRAM

	jsr RndColour		; Random fg colour (preserves X,Y)
	ora paint_temp		; Splice bg+fg
	sta VERA_DATA0		; Write char colour to VRAM
	bra @next

@cont:
	rts

;-------------------------------------------------------------------
; v_setinc - Sets the VERA increment
;
;   Prior   : (optional) Call v_setxy to set the VERA "cursor"
;   On Entry: A - VERA stepping value (1,2,etc.)
;   On Exit:  Y-reg destroyed
;             All other regs preserved.
;
; Notes: Use 1 for v_chrout (sets colour for each character)
;        Use 2 if writing text directly with current colours
;-------------------------------------------------------------------
v_setinc:
        asl                     ; Shift increment value to upper nibble
        asl
        asl
        asl
        ora #$01                ; bank = 1
        sta VERA_ADDR_HI
        rts
;-------------------------------------------------------------------
; v_chrout - Display a PETSCII_UL character using VERA
;            Uses the currently set xy location and bg/fg colours
;
;   Prior   : Call v_setinc with increment = 2
;            (optional) Call v_setxy to set the VERA "cursor"
;   On Entry: A - PETSCII character to display
;   On Exit:  Y-reg destroyed
;             All other regs preserved.
;
; Notes: Maps PETSCII_UL character to VERA character index
;        Uses vcolours variable
;-------------------------------------------------------------------
v_chrout:
        cmp #$40
        bcc @disp_char
        cmp #$60
        bcc @low_conv
        cmp #$a0
        bcs @low_conv
        sec
        sbc #$20
        bra @disp_char
@low_conv:
        sec
        sbc #$40                ; Convert PETSCII_UL from $40 and above to index
@disp_char:
        sta VERA_DATA0          ; write to VRAM, auto‑increments to colour
        ldy vcolours
        sty VERA_DATA0          ; write to VRAM, auto-increments to next text
        rts

;-------------------------------------------------------------------
; v_setxy - Set VERA X,Y coordinates for subsequent operations
;
;   On Entry: X - column
;             Y - row
;   On Exit:  A-reg destroyed
;             All other regs preserved
;
; Notes: similar to PLOT *BUT* gets xy registers correct
;-------------------------------------------------------------------

V_setxy:
        txa                     ; Column to a-reg
        asl                     ; Column x 2 = line offset
        sta VERA_ADDR_LO        ; low byte *** ASSUMES low byte of VERA_TEXT_BASE is zero ***
        tya                     ; Row
        clc
        adc #>VERA_TEXT_BASE
        sta VERA_ADDR_MID       ; mid byte
        rts


;-------------------------------------------------------------------
; DownCount16 - 16-bit down counter
; Counts the exact number in count and handles zero (it skips the call)
;
;   Prior   : Initialize count, count+1 to the 16-bit count
;   On Entry: n/a
;   On Exit:  C = 0 count is finished
;             C = 1 - count should continue
;-----------------------------------------------------

DownCount16:
	pha
    sec
    lda count
    sbc #1
    sta count
    lda count+1
    sbc #0
    sta count+1
	pla
	rts

;---------------------------------------------------------------
; div3 - Integer divide by 3 (A\3)
;
;   On Entry: A-reg = dividend
;   On Exit : A-reg = quotient
;             All other regs are preserved
;
; 18 bytes, 30 cycles
; Uses 1 byte of ZP: Temp0
;---------------------------------------------------------------
div3:
  sta  Temp0
  lsr
  adc  #21
  lsr
  adc  Temp0
  ror
  lsr
  adc  Temp0
  ror
  lsr
  adc  Temp0
  ror
  lsr
  rts

;---------------------------------------------------------------
; RndColour - Returns a random colour 0-15
;   Prior   : Seed rand8 with a call to RndInit
;   On Entry: n/a
;   On Exit : A-reg contains value
;             All other regs are preserved
;---------------------------------------------------------------
RndColour:
	jsr rand8		; A-reg = 0-255
	lsr				; Divide by  2... A-reg = 0-127
	lsr			    ; Divide by  4
	lsr				; Divide by  8
	lsr				; Divide by 16
	rts

;---------------------------------------------------------------
; RndChrIndex - Returns a random PETSCII_UL character index 0-127
;   Prior   : Seed rand8 with a call to RndInit
;   On Entry: n/a
;   On Exit : A-reg contains value
;             All other regs are preserved
;---------------------------------------------------------------
RndChrIndex:
	jsr rand8		; A-reg = 0-255
	lsr				; Divide by 2... A-reg = 0-127
	rts

;---------------------------------------------------------------
; RndRow - Returns a random row number 0-60
;   Prior   : Seed rand8 with a call to RndInit
;   On Entry: n/a
;   On Exit : A-reg contains random number 0-60
;             All other regs are preserved
;---------------------------------------------------------------
RndRow:
	jsr rand8		; A-reg = 0-255
	lsr				; Divide by 2...
	lsr				; Divide by 2... A-reg = 0-63
	cmp #60
	bcs RndRow	; Out or range, so get another one
@exit:
	rts

;---------------------------------------------------------------
; RndColumn - Returns a random column number 0-79
;   Prior   : Seed rand8 with a call to RndInit
;   On Entry: n/a
;   On Exit : X-reg is destroyed	
;             All other regs are preserved
;---------------------------------------------------------------
RndColumn:
	jsr rand8		; A-reg = 0-255
	jsr div3	    ; A-reg = 0-85
	cmp #80
	bcs RndColumn	; Out or range, so get another one
@exit:
	rts

;---------------------------------------------------------------
; RndInit - Initializes rand8
;   Prior   : n/a
;   On Entry: n/a
;   On Exit : n/a
;             All other regs are preserved
;---------------------------------------------------------------
RndInit:
	jsr ENTROPY_GET		; rnd in A,X,Y
	sta a1
	stx x1
	sty c1
	rts

;---------------------------------------------------------------
;; X ABC Algorithm Random Number Generator for 8-Bit Devices
;;
;; Algorithm from EternityForest, slight modification by Wil
;; https://www.electro-tech-online.com/threads/ultra-fast-
;;   pseudorandom-number-generator-for-8-bit.124249/
;; Implementation and test: Wil
;; This version stores the seed as arguments and uses self-modifying code
;; Routine requires 38 cycles (without the rts) / 28 bytes
;; Return values are in A and, if a 16 bit value is needed
;; also in _rand8_highbyte
;---------------------------------------------------------------
;.export _rand8:=rand8, _rand8_highbyte:=b1

rand8:	
	inc x1
	clc
x1=*+1
	lda #$00	;x1
c1=*+1
	eor #$c2	;c1
a1=*+1
	eor #$11	;a1
	sta a1
b1=*+1
	adc #$37	;b1
	sta b1
	lsr
	eor a1
	adc c1
	sta c1
	rts

;---------------------------------------------------------------
; Delay - Waits a given number of 1/30 sec (33.3 ms) intervals
; +----+----------+
; | X  | ~ delay  |
; +----+----------+
; | 30 | 1.0 sec  |
; | 15 | 0.5 sec  |
; |  7 | 0.25 sec |
; |  0 | 8.5 sec  | * X=0 waits 256 intervals
; +----+----------+
;   On Entry: X = number of intervals to wait
;   On Exit : X-reg is destroyed	
;             All other regs are preserved
;---------------------------------------------------------------
Delay:
	wai				; Halts for about 1/60 sec
	wai				; Halts for about 1/60 sec
	dex
	bne Delay
	rts

;---------------------------------------------------------------
; v_strout - Write a PETSCII_UL string directly to the screen
;            using VERA
;
;
;   Prior   : Prepare screen and character set
;	          Call v_setinc with increment 1   
;;            (optional) set vcolours (bg+fg)
;             (optional) call v_setxy
;   On Entry: X,Y = pointer to zero-terminated string
;                   to write to the screen
;   On Exit:  A,Y are destroyed
;			  All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;---------------------------------------------------------------
v_strout:
		stx MemPtr
		sty MemPtr+1
	    ldy #0
_next:
		lda (MemPtr),y
		beq _done
		phy
		jsr v_chrout
		ply
		iny
		bne _next	; falls through if y wraps around
_done:
		rts

;---------------------------------------------------------------
; StrOut_XY:
;
; SPECIAL "C64/CX16" VERSION OF THIS FUNCTION THAT OPERATES
; ON A POINTER IN X,Y
;
;   Prior   : Prepare screen and character set   
;   On Entry: X,Y = pointer to zero-terminated string
;                   to write to the screen
;   On Exit:  C = 0 - success
;                 1 - error
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;---------------------------------------------------------------
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
		bcs _done	; error
		iny
		bne _next	; falls through if y wraps around
_done:
		ply
		plx
        pla
		rts


HelloStr0:    .petscii "X16 Assembler in ROM Demo #1.",$00
HelloStr1:	  .petscii "Welcome!",$00

AsmStr0:     .petscii " X16 Assembler ",$00
AsmStr1:     .petscii "    In ROM     ",$00
SpaceStr:    .petscii "               ",$00

BoxAsmStr0:  .petscii BOX_VBAR,"X16 Assembler",BOX_VBAR,$00
BoxAsmStr1:  .petscii BOX_VBAR,"   In ROM    ",BOX_VBAR,$00
BoxTopStr:   .byte BOX_TL,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR
			 .byte BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR
			 .byte BOX_HBAR,BOX_HBAR,BOX_TR,$00

BoxBotStr:	.byte BOX_BL,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR
			.byte BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR,BOX_HBAR
			.byte BOX_HBAR,BOX_HBAR,BOX_BR,$00

ExitStr0:    .petscii "End of run. Have a nice day!",$00


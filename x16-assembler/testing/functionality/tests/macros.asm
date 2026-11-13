; *******************************************************************************************
;
;									Test assembly of macros
;
; *******************************************************************************************

		* = $8000

; -------------------------------------------------------------------------------------------
;
;		This macro prints out p2 copies of character p1
;
; -------------------------------------------------------------------------------------------

mchars 	.macro
		ldx 	#\2
_loop
		lda 	#\1
		jsr 	$FFD2
		dex
		bne 	_loop
		.endm

		mchars 42,3
		mchars 43,4
		mchars 32,5,12 			; note, there is no check on excess parameters like here.
								; it does check there are sufficient.
; -------------------------------------------------------------------------------------------
;
;		This macro prints a string (theoretically, the function at $FFFC does not exist !)
;
; -------------------------------------------------------------------------------------------

textpr  .macro
		ldx 	#_textmsg & $FF
		ldy 	#_textmsg >> 8
		jsr 	$FFFC
		bra 	_continue
_textmsg:
		.text 	\1,0
_continue		
		.endm

		textpr "Hello"
		textpr "World !"		
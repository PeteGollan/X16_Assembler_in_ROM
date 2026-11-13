;----------------------------------------------------------------------------
; Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
; March 2026 for the X16-Assembler in ROM project
;
; farcalls.asm 
;   These functions are relocated to our main RAM BANK. They bridge between
;   the assembler ROM bank and system ROM.
;
; Note:
;   If these functions take up more that 256 bytes, 
;   function TA_CopyCallToRAM will require adjustment.
;----------------------------------------------------------------------------

; This table is at the start of STORAGE in HOME_RAM_BANK
; Do *NOT* call these directly (e.g. ROM_FarSetnam), instead call
; the RAM version (e.g. FarSETNAM):

ROM_FarSETNAM:
	stz ROM_BANK_REG
	jsr	$FFBD			; SETNAM
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarSETLFS:
	stz ROM_BANK_REG
	jsr $FFBA			; SETLFS
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarOPEN:
	stz ROM_BANK_REG
	jsr	$FFC0			; OPEN
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarREADST:
	stz ROM_BANK_REG
	jsr	$FFB7			; READST
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarCLOSE:
	stz ROM_BANK_REG
	jsr	$FFC3			; CLOSE
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarCLRCHN:
	stz ROM_BANK_REG
	jsr	$FFCC			; CLRCHN
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarCHKIN:
	stz ROM_BANK_REG
	jsr $FFC6
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_FarCHKOUT:
	stz ROM_BANK_REG
	jsr $FFC9			; CHKOUT
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

; Not needed for now
;FarCHRIN:
;	stz ROM_BANK_REG
;	jsr $FFCF			; CHRIN
;	pha
;	lda #HOME_ROM_BANK
;	sta ROM_BANK_REG
;	pla
;	rts

ROM_FarCHROUT:
	stz ROM_BANK_REG
	jsr	$FFD2			; CHROUT
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

; Used by FileExists
ROM_FarGETIN:
	stz ROM_BANK_REG
	jsr $FFE4			; GETIN
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_Far2MCIOUT:
	stz ROM_BANK_REG
	jsr	$FEB1			; MCIOUT
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

ROM_Far2MACPTR:
	stz ROM_BANK_REG
	jsr	$FF44			; MACPTR
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts

; Imagine if we tried this from a ROM bank... ;)
ROM_FarROM_sta:
	    lda ROM_bank            ; bank #
        sta ROM_BANK_REG
        tya                     ; byte to store is in a-reg
        sta (Temp0)
        lda #HOME_ROM_BANK      ; Switch us back home...
        sta ROM_BANK_REG
        rts

ROM_FarSETTIM:
	stz ROM_BANK_REG
	jsr $FFDB			; SETTIM
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts


ROM_FarRDTIM:
	stz ROM_BANK_REG
	jsr $FFDE			; RDTIM
	pha
	lda #HOME_ROM_BANK
	sta ROM_BANK_REG
	pla
	rts


;---------------------------------------------------------------------------------------------
; sec_utils.asm - Common utility functions for the write and read sector programs.
;
; Included in the main program source files.
;
; Pete Wyspianski (AKA Gollan)
; October 2026
; Ottawa, Canada
;---------------------------------------------------------------------------------------------
; Contents:
;   CONTROL CODES
;   CalcSectorChecksum - Calculates a simple checksum for a specified sector_buf
;   CreateSector - Creates a sector in write_sector_buf using CurSector
;   GetYN - Waits until Y, N, RETURN, or ESC is pressed
;   GetCharInput - reads a single character of keyboard input
;   GetLineInput - Reads a line of keyboard input
;   StrOut
;   StrLen
;   Hex16Dec - Converts a 16-bit word to ASCII decimal digits
;   Div10 - Divides a 16-bit word by 10 returning the quotient and remainder.
;   ConvDec16 - Converts a 1-5 digit decimal number to 16-bit hexidecimal (0-65535)
;   FileExists - Checks if a file exists
;   WordOut - prints a given word in hexadecimal
;   Hex3Out - prints the hex value of 3 digit value
;   ByteOut - prints the hex value of a given byte


;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------

BREAK = $03   ; Ctrl-C
BELL  = $07   ; More like a beep
LF    = $0A   ; AKA \n - New line in Linux AND X16-EDIT ISO mode
CR    = $0D   ; AKA \r - New line character in Commodore and CX16 PETSCII
BS    = $14   ; Backspace key and character
ESC   = $1B   ; ESC key
SPACE = $20   ; Space key and character
DQ    = $22   ; Double quote (stress-free way to include double quote in strings)


ISO_OFF = $8F   ; Also clears screen
PETSCII_U = $8E
PETSCII_UL = $0E
CLS = $93

; Some assemblers do dodgy things with text so..
PETSCII_A = $41           ; PETSCII "A"
PETSCII_B = $42           ; PETSCII "B"
PETSCII_C = $43           ; PETSCII "C"
PETSCII_M = $4D           ; PETSCII "M"
PETSCII_N = $4E           ; PETSCII "N"
PETSCII_Y = $59           ; PETSCII "Y"
PETSCII_Z = $7A           ; PETSCII "Z"


;------------------------------------------------------------------
; CalcSectorCheckum 
;       Calculates a simple checksum for a specified sector_buf
;
; On Entry: a,x - pointer to a sector_buf to use
; On Exit:  SectorCS contains the checksum
;
; Uses: (ZP) SectorCS, SecPtrLow, SecPtrHigh
; Note: this code assumes that SECTOR_SIZE is 512
;------------------------------------------------------------------
CalcSectorChecksum:

        sta SecPtrLow              ; Save the sector_buf pointer
        stx SecPtrLow+1
        sta SecPtrHigh
        inx                        ; Add $100 to SecPtrHigh
        stx SecPtrHigh+1

        stz SectorCS
        stz SectorCS+1

        ldy #0                  ; Index
@next:
        clc
        lda (SecPtrLow),y        ; Add a word from low half of buffer to SectorCS
        adc SectorCS
        sta SectorCS
        iny
        lda (SecPtrLow),y
        adc SectorCS+1
        sta SectorCS+1
        dey

        clc
        lda (SecPtrHigh),y   ; Add a word from high half of buffer to SectorCS
        adc SectorCS
        sta SectorCS
        iny
        lda (SecPtrHigh),y
        adc SectorCS+1
        sta SectorCS+1

        iny             ; y-reg has already been incremented once, so one more for next word
        bne @next
  
        rts

;-----------------------------------------------------------
; CreateSector 
;       Create a sector in write_sector_buf using CurSector
;
; On Entry: n/a
; On Exit:  n/a
;
; Uses: write_sector_buf
;
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
CreateSector:

; Populate the sector with its CurSector ID word:

        ldx #0                  ; Index
@next:
        lda CurSector           ; LSB of sector ID
        sta write_sector_buf,x        ; Low half of buffer
        sta write_sector_buf+$100,x   ; High half of buffer
        lda CurSector+1         ; MSB of sector ID
        sta write_sector_buf+1,x      ; Low half of buffer
        sta write_sector_buf+$101,x   ; High half of buffer
        inx
        inx
        bne @next

; Set bytes 2 and 3 to zero for checksum computation:

        stz write_sector_buf+2
        stz write_sector_buf+3

; Get the checksum for this buffer with the CS set to zero:

        lda #<write_sector_buf
        ldx #>write_sector_buf
        jsr CalcSectorChecksum

; Calculate the final checksum:

        lda #$ff
        sec
        sbc SectorCS
        sta write_sector_buf+2
        lda #$ff
        sbc SectorCS+1
        sta write_sector_buf+3 
        rts


;-----------------------------------------------------------
; GetYN - Waits until Y, N, RETURN, or ESC is pressed
;
; On Entry: n/a
; On Exit:  C=0 A character was pressed:
;           a-reg = char pressed ("Y","N")
;             If RETURN was pressed: returns "Y"
;           C=1 ESC was pressed, no input
;             ax-regs destroyed
;
; Uses: n/a
;-----------------------------------------------------------
GetYN:
        jsr GETIN   ; Trashes y-reg
        cmp #0
        beq GetYN
        cmp #ESC             ; ESC pressed?
        beq @exit_esc
        cmp #CR              ; ENTER pressed?
        bne @not_CR          ; Taken if NOT
        lda #PETSCII_Y       ; Default is 'Y'
        bra @exit

@not_CR:
        and #$5F             ; Shift UPPER characters to PETSCII
        cmp #PETSCII_Y
        beq @exit            ; Taken if so
        cmp #PETSCII_N
        bne GetYN            ; Taken if NOT

@exit:
        clc
        rts

@exit_esc:
        sec
        rts



;-----------------------------------------------------------
; GetCharInput - reads a single character of keyboard input
;                and returns SCREEN CODES (see Notes)
; On Entry: n/a
; On Exit:  C=0 - A character or RETURN was pressed
;             a- reg = char
;           C=1 ESC was pressed, no input
;
; NoteS: Restricted to printable characters
;        Returns SCREEN CODES, not PETSCII
;  ***** This should call a ScreenCodeToPETSCII function
;-----------------------------------------------------------
GetCharInput:

        lda #blink_enable   ; Turn ON the blinking cursor:
        ldx #0              ; 0=blink enable
        jsr EXTAPI

@key_wait:
        jsr GETIN             ; Trashes y-reg
        cmp #0
        beq @key_wait

        pha                  ; A key was pressed, so turn OFF the blinking cursor
        lda #blink_enable
        ldx #$FF             ; $FF=blink disable
        jsr EXTAPI
        pla

        cmp #CR              ; ENTER key?
        beq @exit_ok         ; Taken if so
        cmp #ESC             ; ESC key?
        beq @exit_esc        ; Taken if so
        cmp #' '             ; Printable?
        bcc @key_wait        ; Taken if NOT (try again)
        cmp #PETSCII_Z+1
        bcs @key_wait        ; Taken if NOT printable (try again)
        tax                  ; Save the char
        jsr CHROUT           ; Echo printable char...
        txa

; All else falls into exit_ok:
@exit_ok:
        clc                  ; Success exit
        rts

@exit_esc:
        sec                 ; Input abandoned...
        rts



;-----------------------------------------------------------
; GetLineInput - reads a line of keyboard input
;
; On Entry: a,x= pointer to the buffer
; On Exit:  C=0 ENTER/RETURN was pressed:
;             buffer contains null-terminateded input
;             y-reg = number of chars entered (0 if RETURN)
;             ax-regs destroyed
;           C=1 ESC was pressed, no input
;             ax-regs destroyed
;
; Uses: (ZP) scratch0, (ZP) buf_ptr
;-----------------------------------------------------------

GetLineInput:

        sta buf_ptr
        stx buf_ptr+1

        stz scratch0        ; kbd_buf index
@read_char:

        lda #blink_enable   ; Turn ON the blinking cursor:
        ldx #0              ; 0=blink enable
        jsr EXTAPI

@key_wait:
        jsr GETIN   ; Trashes y-reg
        cmp #0
        beq @key_wait

        pha                   ; A key was pressed, so turn OFF the blinking cursor:
        lda #blink_enable
        ldx #$FF             ; $FF=blink disable
        jsr EXTAPI
        pla

        cmp #CR              ; ENTER key?
        beq @exit_ok         ; Taken if so
        cmp #ESC             ; ESC key?
        beq @exit_esc        ; Taken if so
        cmp #BS              ; Backspace?
        beq @do_backspace    ; Taken if so

; No other control characters, so screen them out:
        cmp #' '             ; Space is lowest printable char
        bcc @read_char       ; Ignore char if it is lower than space

; We *could* check for high range chars here, but we don't...
        ldy scratch0         ; Fetch kbd_buf index
        sta (buf_ptr),y      ; Save character       
        jsr CHROUT           ; Echo character (xy-regs are preserved)
        iny                  ; Increment index
        sty scratch0
        cpy #KBD_BUF_SIZE    ; Are we at the max?
        bne @read_char       ; Taken if not
        dec  scratch0        ; Ignore overflow characters

        lda #BS
        jsr CHROUT           ; And back up the cursor
        lda #SPACE
        jsr CHROUT           ; And erase it
        lda #BS
        jsr CHROUT           ; And back up
        bra @read_char

@do_backspace:
        ldy scratch0         ; Fetch kbd_buf index
        cpy #0               ; At start of kbuf?
        beq @read_char       ; Nothing to delete

        dec scratch0         ; Move back one char
        lda #BS
        jsr CHROUT           ; Back up the cursor
        lda #SPACE
        jsr CHROUT            ; Overwrite char
        lda #BS               ; Backspace again
        jsr CHROUT            ; Move cursor left
        bra @read_char

@exit_ok:
        ldy scratch0         ; Fetch kbd_buf index
        lda #0               ; Null terminate
        sta (buf_ptr),y
        clc                  ; Success exit
        rts

@exit_esc:
        lda #0
        sta (buf_ptr)
        sec                 ; Input abandoned...
        rts

;-----------------------------------------------------
; StrOut:
;   Prior   : Prepare screen and character set   
;   On Entry: A,X = pointer to zero-terminated string
;                   to write to the screen
;   On Exit:  C = 0 - success
;                 1 - error
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;-----------------------------------------------------
StrOut:
		pha
		phy
		sta MemPtr
		stx MemPtr+1
	    ldy #0
@next:
		lda (MemPtr),y
		beq @done
		jsr CHROUT
		bcs @done	; error
		iny
		bne @next	; falls through if y wraps around
@done:
		ply
		pla
		rts


;-------------------------------------------------------------------------
; StrLen - Returns the length of a zero-terminated string
;
;   On Entry: A,X = pointer to zero-terminated string
;   On Exit:  C = Y = the length of the string
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;
; Note: The maximum measurable string length is 255 characters
;       If a string is longer than 256 characters, 255 will be returned 
;-------------------------------------------------------------------------
StrLen:
    sta MemPtr
    stx MemPtr+1

    ldy #0
; Look for the null byte at the end:
@1:
    lda (MemPtr),y
    beq @null_found
    iny
    bne @1
; String length overflow, return $255
    dey

@null_found:
    rts

;-----------------------------------------------------------
; Hex16Dec - Converts a 16-bit word to ASCII decimal digits
;
; On Entry: MemPtr - points to string buffer with room for
;                    up to 5 digits plus null terminator.
;           ax - word to be converted
;
; On Exit:  (MemPtr) contains 1-5 ASCII digits and a null
;            terminator
;
;           All regs destroyed
;
; Uses : (ZP) MemPtr
;        Hex16Dec_buf (internal buffer - 6 bytes)
;        quot (2 bytes) - parameter to Div10
; Calls: Div10
;-----------------------------------------------------------
Hex16Dec:
        sta quot         ; Set up call to Div10
        stx quot+1

        ldx #0           ; x-reg is our internal buffer index

@next:
        lda quot
        sta num
        lda quot+1
        sta num+1
        phx
        jsr Div10       ; Get first digit
        plx
        lda rem
        clc             ; Convert to ASCII
        adc #'0'
        sta Hex16Dec_buf,x
        inx

; Check the quotient:
        lda quot
        ora quot+1      ; Cheeky way to check 16-bit for zero
        bne @next       ; Taken if quotient is not zero...

; Prune the leading zeros and reverse the digits into the specified buffer:

; Find the first non-zero digit. x-reg points past the last digit.
@next1:
        dex             ; Point at the last digit
        bmi @zero       ; Taken if the whole number is zero
        lda Hex16Dec_buf,x
        cmp #'0'        ; Zero?
        beq @next1      ; Take if so...

; The string contains at least one non-zero digit and y-reg points at the first one:

        ldy #0          ; Index to the caller-specified buffer
@next2:
        lda Hex16Dec_buf,x
        sta (MemPtr),y
        iny
        dex
        bpl @next2
        bra @null_term_exit

; The number is zero so set it up:
@zero:
        ldy #0          ; Has to be set up on this branch.
        lda #'0'
        sta (MemPtr),y  ; Save the '0' character
@null_term_exit:
;        iny
        lda #0
        sta (MemPtr),y  ; null-terminate
        rts

Hex16Dec_buf: .res 6           ; 5 digits and a null (but not needed)


;-----------------------------------------------------------
; Div10 - Divides a 16-bit word by 10 returning the
;         quotient and remainder.
;
; On Entry: num  - set to numerator (16 bits)
;
; On Exit:  quot - quotient (16 bits)
;           rem  - remainder (8 bits)
;
;           a,x-regs destroyed, y-reg preserved
;
; Uses: num (2 bytes), quot (2 bytes), rem (1 byte)
;
; Note:
;   * Could speed this up a small amount by using zp for
;     variables
;-----------------------------------------------------------

Div10:
        stz rem              ; Initialize our outputs
        stz quot
        stz quot+1

        ldx #16              ; Processing 16 bits
@next:
        asl num              ; Generate 1 bit of the quotient
        rol num+1
        rol rem

        lda rem
        cmp #10
        bcc @zero_bit

        sbc #10
        sta rem
        sec
        bra @shift_quot

@zero_bit:
        clc

@shift_quot:
        rol quot
        rol quot+1
        dex
        bne @next
        rts


;-----------------------------------------------------------
; ConvDec16 - Converts a 1-5 digit decimal number to 16-bit
;            hexidecimal (0-65535)
;
; On Entry: ax - pointer to a null-terminated string
;                containing 1-5 decimal digits (0-65535)
; On Exit:  C=0 ax contain the 16-bit value
;           C=1 The string was empty, contained non-numeric
;               characters, or overflowed 16 bits (see notes).
;
; Uses: (ZP) MemPtr, scratch0 , scratch1
;
; Notes:
;   If the calling function ensures that the string has 1-5
;   decimal digits, then the error return can only be
;   16-bit overflow (a 5-digit number greater than 65535).
;-----------------------------------------------------------
ConvDec16:
        sta MemPtr              ; Save the string
        stx MemPtr+1
        stz scratch0            ; Initialize the value
        stz scratch0+1
        ldy #0                  ; y-reg is the string index

@next_digit:
        lda (MemPtr),y          ; Fetch next digit
        beq @exit_ok            ; Taken if end of string

        cmp #'0'                ; Valid decimal digit?
        bcc @exit_fail          ; Taken if NOT
        cmp #'9'+1
        bcs @exit_fail          ;  Taken if not
        sec
        sbc #'0'                ; Convert to number 0-9
        clc
        adc scratch0            ; Add the digit to the value
        sta scratch0
        lda scratch0+1
        adc #0
        sta scratch0+1
        bcs @exit_fail          ; Taken if 16-bit overflow

        iny                     ; Index next digit
        lda (MemPtr),y          ; End of string?
        beq @exit_ok            ; Taken if so

; To add another decimal digit, first multiply the current value by 10:
        lda scratch0            ; Save original value for later...
        sta scratch1            ; LSB
        lda scratch0+1
        sta scratch1+1          ; MSB

        jsr @x2                 ; scratch0 x2
        bcs @exit_fail          ; 16-bit overflow
        jsr @x2                 ; scratch0 x4
        bcs @exit_fail          ; 16-bit overflow

; Add the original value saved earlier to scratch0:
        clc
        lda scratch0
        adc scratch1
        sta scratch0            ; lsb x 5 

        lda scratch0+1
        adc scratch1+1
        sta scratch0+1          ; msb x 5
        bcs @exit_fail          ; 16-bit overflow

; With the value multiplied by 5, do one more x2 get x10:
        jsr @x2
        bcc @next_digit         ; Continue if no olverflow

@exit_fail:
        rts
      
@exit_ok:
        clc
        lda scratch0            ; Return the value
        ldx scratch0+1        
        rts


; Function to multiply scratch0 (16 bits) by 2:
; If c=1 on exit, 16-bit overflow occured.
@x2:
        clc
        lda scratch0
        asl a                   ; x 2
        sta scratch0
        lda scratch0+1
        rol a
        sta scratch0+1
        rts




;----------------------------------------------
; WordOut - prints a given word in hexadecimal
;
; inputs : a,x = word to print l,h
; outputs: a reg destroyed
; uses   : none
; calls  : ByteOut
; notes  : none

WordOut:
	pha                    	 ; save low byte
	txa
	jsr     ByteOut          ; show high byte
	pla
	bra     ByteOut          ; show low byte

;-----------------------------------------------------------
; Hex3Out - prints the hex value of 3 digit value
;
; inputs : a,x = 3 hex digits to print (l,h)
; outputs: a-reg = destroyed
; uses   : none
; calls  : CHROUT
; notes  : prints hex A-F in upper case
Hex3Out:

 	pha                    	 ; save low byte
	txa
	jsr     prnibble0        ; low digit of high byte
	pla
	bra     ByteOut          ; show low byte

;-----------------------------------------------------------
; ByteOut - prints the hex value of a given byte
;
; inputs : a-reg = byte to print
; outputs: a-reg = destroyed
; uses   : none
; calls  : CHROUT
; notes  : prints hex A-F in upper case

ByteOut:
		pha                     ; save value
		lsr                     ; spin hi nibble->low
		lsr
		lsr
		lsr
		jsr     prnibble        ; show high nibble
		pla                     ; then low nibble...
prnibble0:                
		and     #$0f            ; form table index
prnibble:
                phx
                tax                     ; use digit number as index
                lda hextab,x
                plx

		;clc
		;adc     #'0'
		;cmp     #'9'+1           ; need adjustment?
		;bcc     @noadj          ; taken if not (0-9)
		;adc     #6              ; 6 + set carry = 7
@noadj:	
		jmp     CHROUT     	    ; preserves all regs

hextab:	.byte	"0123456789ABCDEF"

;-----------------------------------------------------
; FileExists
;
; Written by Tony3068 and posted on Discord:
; https://discord.com/channels/547559626024157184/629863245934755860/1359286644150108374
;
;   On Entry:   A   = length of name
;               X,Y = pointer to filename string
;   On Exit:  C = 0 - File exists
;                 1 - File does NOT exist
;             All other regs are preserved
;
; Note: The call setup is the same as SETNAM
;-----------------------------------------------------
FileExists:

        pha
        phx
        phy

; Open and then immediately close the file:
        jsr SETNAM 
        lda #FILE_EXISTS_LFN        ; LFN
        ldx #8                      ; Device
        tay                         ; Use LFN as secondary
        jsr SETLFS
        jsr OPEN
        lda #FILE_EXISTS_LFN       ; LFN
        jsr CLOSE

; Open the error channel and check the result:
        lda #0
        ldx #<Dummy_name
        ldy #>Dummy_name
        jsr SETNAM
        lda #15
        ldx #8
        ldy #15
        jsr SETLFS       ; All regs preserved
        jsr OPEN

        ldx #15
        jsr CHKIN        ; Destroys all regs, but it is OK
        jsr GETIN
        cmp #'0'
        bne _NotFound
        jsr GETIN
        cmp #'0'
        beq _Found

_NotFound:
        jsr _flushchars
        jsr CLRCHN
        ply
        plx
        pla
        sec
        rts

_Found:
        jsr _flushchars
        jsr CLRCHN
        ply
        plx
        pla
        clc
        rts

; Clear the rest of the error message:
_flushchars:
        jsr GETIN
        cmp #13
        bne _flushchars
        lda #15
        jsr CLOSE
        rts

; dummy file name target
Dummy_name:
    .byte 0


; ca65 compatibility:
num:   .res 2       ; Numerator
quot:  .res 2       ; Quotient
rem :  .res 1       ; Remander

HelloWriteStr:    .byte CLS,PETSCII_UL
;-this is an alignment helper-------------->    v0.1 | 
                  .byte "+---------------------------+",CR
                  .byte "| Write Sector Utility v",VERS_MAJOR+'0','.',VERS_MINOR+'0'," |",CR
                  .byte "+---------------------------+",CR,CR,$00

HelloReadStr:    .byte CLS,PETSCII_UL
;-this is an alignment helper-------------->   v0.1 | 
                  .byte "+--------------------------+",CR
                  .byte "| Read Sector Utility v",VERS_MAJOR+'0','.',VERS_MINOR+'0'," |",CR
                  .byte "+--------------------------+",CR,CR,$00


Input_help_msg:   .byte CR,"ENTER for default(*) or ESC to exit:",CR,CR,$00

ByeStr:          .byte CR,"End of run. Have a great day.",CR,CR,$00

HowMany_prompt:  .byte "How many sectors (500*) (1-65535)?",$00
ReadMethod_prompt:  .byte "Read method (C)CHRIN or (M*)MACPTR?",$00

DEFAULT_FNAME:   .byte "sec.dat",$00    ; NOTE: *** change FileName_prompt to match this
DEFAULT_LOG_FNAME: .byte "sec.log",$00  ; NOTE: *** change LogFileName_prompt to match this

FileName_prompt:    .byte CR,"Data file name (sec.dat*)?",$00
LogFileName_prompt: .byte CR," Log file name (sec.log*)?",$00

YN_prompt:      .byte "Y(*)/n",$00

; Formatted for write params:
nSectors_review:   .byte CR,CR,"Sectors  :",$00
FileName_review:   .byte       "File name:",$00

; Formatted for read params:
ReadMethod_review:  .byte CR,CR,"Read method   :",$00
FileName_review2:   .byte       "Data file name:",$00
LogFileName_review: .byte       " Log file name:",$00

ReadMethod_CHRIN:       .byte "CHRIN",$00
ReadMethod_MACPTR:      .byte "MACPTR",$00


overwrite_msgD: .byte "Data file ",DQ,$00
overwrite_msgL: .byte "Log file ",DQ,$00
overwrite_msg1: .byte DQ," already exists. Overwrite it Y(*)/n?",$00

nofile_msg: .byte "DATA FILE DOES NOT EXIST:",$00

writing_msg: .byte "Writing sectors to file, ESC to exit...",CR,CR,$00
reading_msg: .byte "Reading and validating sectors from file...",CR,CR,$00

Halt_msg:      .byte CR,CR,"STOPPED.",CR,$00
read_err_msg0: .byte CR,CR,"SECTOR $",$00
read_err_msg1: .byte" READ ERROR.",CR,$00

sector_msg0: .byte " $",$00
sector_msg1: .byte ": $",$00
sector_msg2: .byte " -> $",$00
sector_msg3: .byte CR,$00

log_file_msg0:   .byte "Data file:",$00
log_file_msg1:   .byte CR,CR,$00
log_header_msg0:  .byte CR,"Sector $",$00
log_trailer_msg0: .byte CR,$00     ; For now
sector_size_err0: .byte " Size error. Read ",$00
sector_size_err1: .byte " bytes, expected ",$00
sector_size_err2: .byte " bytes.",CR,$00

log_errors_msg0: .byte " ",$00
log_errors_msg1: .byte " compare errors.",CR,$00
log_errors_msgx: .byte " compare error.",CR,$00 ; Yes, we went there.

; Strings used by OpenFileWrite:
OverwriteStr:   .byte $40,$3A,$00       ; "@:" some assemblers don't encode this correctly
WriteModeStr:   .byte ",s,w",$00

;------------------
; Buffers
;------------------
kbd_buf:        .res KBD_BUF_SIZE       ; Cant be smaller than the other buffers
str_buf:        .res STR_BUF_SIZE
fname_buf:      .res STR_BUF_SIZE
log_fname_buf:  .res STR_BUF_SIZE

write_sector_buf:
        .res SECTOR_SIZE

read_sector_buf:
        .res SECTOR_SIZE
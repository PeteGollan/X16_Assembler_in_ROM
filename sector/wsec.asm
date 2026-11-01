;---------------------------------------------------------------------------------------------
; wsec.asm - Write Sector Utility
;
; Pete Wyspianski (AKA Gollan)
; October 2026
; Ottawa, Canada
;
; Sector format:
;   512 bytes (256 words)
;   Filled with the sector number ($0000-$FFFF)
;   Checksum at $0002 and $0003 is the value that makes the entire sector sum to $FFFF
;---------------------------------------------------------------------------------------------
VERS_MAJOR = 0
VERS_MINOR = 1

        .include "sec.inc"

;---------------------------------------------------------
; Zero Page - $0022-$007F are available
; The linker automatically starts this segment at $22
;---------------------------------------------------------
    .zeropage
    .org $0022  ; Makes the *.lst file easier to read
AuxsZP:          .res 2    ; The auxs serial driver uses $22, so reserve it
MemPtr:          .res 2    ; 2 bytes
MemPtr1:         .res 2    ; 2 bytes
MemPtr2:         .res 2    ; 2 bytes - used by higher-level  functions
SecPtrLow:       .res 2    ; Points to sector_buf ($000..$0FF)
SecPtrHigh:      .res 2    ; Points to sector_buf ($100..$1FF)
scratch0:        .res 2
scratch1:        .res 2
nSectors:        .res 2    ; Number of sectors
CurSector:       .res 2    ; Current sector
SectorCS:        .res 2    ; Sector checksum
buf_ptr:           .res 2   ; Buffer used by GetLineInput

;--------------------------------------------------
; ca65:
        .segment "CODE"
        .org $0801

;--------------------------------------------------
; X16-ASM:
;        .list "sectorw.lst"
;        .direct
;        * = $801

; BASIC stub that SYSes to $08d
    .byte $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

;---------------------------------------------
; MAIN
;---------------------------------------------
main:
        cld                 ; Just in case

        lda #<HelloWriteStr
        ldx #>HelloWriteStr
        jsr StrOut

        lda #<Input_help_msg
        ldx #>Input_help_msg
        jsr StrOut

        jsr GetWriteParams
        bcs @exit               ; ESC pressed, so exit.

        jsr ReviewWriteParams
        bcs @exit               ; ESC pressed or "no" selected, so exit.

        jsr OpenFileWrite
        bcs @exit               ; Taken if file open failed, or overwrite denied

@write_sectors:

        stz CurSector
        stz CurSector+1

        lda #<writing_msg
        ldx #>writing_msg
        jsr StrOut

@next_sector:

; See if the user wants to exit:
        jsr GETIN             ; Trashes y-reg
        cmp #0
        beq @cont             ; Taken if no key
        cmp #ESC              ; User entered ESC?
        beq @exit_halt        ; Taken if so...
        cmp #BREAK            ; User entered ctrl-C?
        beq @exit_halt        ; Taken if so...

@cont:
        jsr CreateSector        ; Make a sector using CurSector

        jsr WriteSector
        bcs @exit_close         ; Taken if something went wrong

        lda #'.'
        jsr CHROUT

        inc CurSector
        bne @check_done
        inc CurSector+1
@check_done:
        lda CurSector           ; Done when next CurSector equals nSectors
        cmp nSectors
        bne @next_sector
        lda CurSector+1
        cmp nSectors+1
        bne @next_sector

@exit_close:
        lda #CR
        jsr CHROUT
        jsr CloseFileWrite

@exit:
        lda #<ByeStr
        ldx #>ByeStr
        jsr StrOut
        rts

; ESC or ctrl-c pressed during write:
@exit_halt:
        lda #<Halt_msg
        ldx #>Halt_msg
        jsr StrOut
        bra @exit_close

;-----------------------------------------------------------
; WriteSector
;       Write prepared write_sector_buf to the open file.
;
; On Entry: SECTOR_FILE_LFN is open for writing
;           sector_buf contains the sector to write
;
; On Exit:  C=0 - Sector was written successfully 
;           C=1 - Sector write failed
;           A-reg has READST code if fail
;
; Uses: write_sector_buf
;
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
WriteSector:

        ldx #SECTOR_FILE_LFN
        jsr CHKOUT
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)

; Write the sector to the file in two chunks:

       ldy #0                  ; Index
@next0:
        lda write_sector_buf,y        ; Write a byte from low half of the sector buffer
        jsr CHROUT              ; y reg preserved
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)
        iny
        bne @next0

       ldy #0                  ; Index
@next1:
        lda write_sector_buf+$100,y   ; Write a byte from high half of the sector buffer
        jsr CHROUT              ; y reg preserved
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)
        iny
        bne @next1

  ; Success exit:
@exit_OK:
        pha
        jsr CLRCHN
        pla
        clc
        rts

; CHKOUT or CHROUT error, a-reg has READST code:
@exit_err:
        pha
        jsr CLRCHN
        pla
        sec     
        rts

;-------------------------------------------------------------
; CloseFileWrite - Close the file
;
; On Entry: n/a
; On Exit:  n/a
;
; Note: we could call READST to get the status, but we don't.
;-------------------------------------------------------------

CloseFileWrite:

        lda #SECTOR_FILE_LFN  ; Close the sector file   
        jsr CLOSE
        rts

;-----------------------------------------------------------
; OpenFileWrite - Open the file for writing
;
; On Entry: n/a
; On Exit:  C=0 - File is open for writing
;           C=1 - File open failed or overwrite was denied
;           A-reg has READST code if open fail
;           or 0 if overwrite was denied
;              
;-----------------------------------------------------------
OpenFileWrite:

; Set up for filename StrLen:
        lda #<kbd_buf      ; Get filename length
        ldx #>kbd_buf
        jsr StrLen         ; y-reg = length

; Set up for FileExists is a bit different:
        tya                ; a-reg = fname length
        ldx #<kbd_buf
        ldy #>kbd_buf

;   On Exit:  C = 0 - File exists
;                 1 - File does NOT exist
        jsr FileExists
        bcs @prep_fname    ; Taken if it does NOT exist (skip overwrite prompt)

; Data file exists, so see if overwrite is OK with the user:

        lda #<overwrite_msgD    ; msgD for Data.
        ldx #>overwrite_msgD
        jsr StrOut
        lda #<kbd_buf
        ldx #>kbd_buf
        jsr StrOut
        lda #<overwrite_msg1
        ldx #>overwrite_msg1
        jsr StrOut

        jsr GetYN
        
        ; Give a little space...
        php
        pha
        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT
        pla
        plp

        bcs @exit_esc      ; Taken if ESC pressed
        cmp #PETSCII_N     ; Rejected?
        beq @exit_esc      ; Taken if so

; Prepare the filename by adding the overwrite string at the beginning and the mode string at the end:
@prep_fname:
        lda #<str_buf      ; Assemble the filename in str_buf
        ldx #>str_buf
        sta MemPtr
        stx MemPtr+1

; Copy the "@:" (overwrite) prefix to the buffer:

       ldx     #0       ; Index for strings being copied
       ldy     #0       ; Index for string at (MemPtr) (str_buf)
@next0:
        lda     OverwriteStr,x
        sta     (MemPtr),y
        beq     @cont0          ; Taken if we loaded/saved a zero
        inx
        iny
        bne     @next0          ; Taken if not
@cont0:

; Copy the file name to the buffer after the prefix
; (y-reg points to the end of the string in the strbuf buffer)

       ldx     #0
@next1:
        lda     kbd_buf,x
        sta     (MemPtr),y
        beq     @cont1          ; Taken if we just loaded/saved a zero
        inx
        iny
        bne     @next1          ; Taken if not
 
 @cont1:

; Append the write mode string to the prefix and filename in the buffer
; (y-reg points to the end of the string in the strbuf buffer)

        ldx     #0
@next2:
        lda     WriteModeStr,x
        sta     (MemPtr),y
        beq      @cont2
        inx
        iny
        bne     @next2           ; Taken if not

@cont2:

; Set up for the SETNAM call:
        tya                                  ; y-reg = strlen
        ldx #<str_buf
        ldy #>str_buf

        jsr SETNAM           ; SETNAM (no return value or flag)

        lda #SECTOR_FILE_LFN    ; Logical file number
        ldx #8                  ; Device number (always 8)
        tay                     ; Secondary is LFN

        jsr SETLFS              ; SETLFS - A-logical file number, X-device (8), y secondary (no return value or flag)
        jsr OPEN                ; OPEN (no params), C=1 on error
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)

; Success exit:
@exit_OK:
        clc
        rts

; For ESC or "no" entered:
@exit_esc:
        lda #0
        sec
        rts

; OPEN error, a-reg has READST code:
@exit_err:
        sec     
        rts

;-----------------------------------------------------------
; ReviewWriteParams - Confirm write parameters
;
; On Entry: n/a
; On Exit:  C=0 - write params confirmed
;           C=1 - ESC was entered, exit request
;-----------------------------------------------------------
ReviewWriteParams:
        lda #<nSectors_review
        ldx #>nSectors_review
        jsr StrOut

; Set up to convert and display nSectors:
        lda #<str_buf
        sta MemPtr
        lda #>str_buf
        sta MemPtr+1

        lda nSectors
        ldx nSectors+1
        jsr Hex16Dec    ; Convert to string

        lda #<str_buf   ; Show nSectors
        ldx #>str_buf
        jsr StrOut

        lda #CR
        jsr CHROUT

        lda #<FileName_review
        ldx #>FileName_review
        jsr StrOut
 
        lda #<kbd_buf   ; Show the filename
        ldx #>kbd_buf
        jsr StrOut
        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT 

        lda #<YN_prompt ; Confirm with user...
        ldx #>YN_prompt
        jsr StrOut
        jsr GetYN

; Give a little space...
        php
        pha
        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT
        pla
        plp

        bcs @exit_esc      ; Taken if ESC pressed
        cmp #PETSCII_N     ; Rejected?
        beq @exit_esc      ; Taken if so


        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT
        rts

@exit_OK:
        clc
        rts

; For ESC or "no" entered:
@exit_esc:
        sec
        rts

;-----------------------------------------------------------
; GetWriteParams - Prompt for write parameters
;
; On Entry: n/a
; On Exit:  C=0 - write params are set
;           C=1 - ESC was entered, exit request
;-----------------------------------------------------------
GetWriteParams:      
        lda #<HowMany_prompt
        ldx #>HowMany_prompt
        jsr StrOut
        lda #<kbd_buf
        ldx #>kbd_buf
        jsr GetLineInput
        bcs @exit_esc        ; Taken if ESC pressed

        cpy #0               ; RETURN entered?
        bne @convert         ; Taken if NOT

; Enter the default value for nSectors:
        lda #<DEFAULT_NSECTORS
        sta nSectors
        lda #>DEFAULT_NSECTORS
        sta nSectors+1
        bra @get_fname

@convert:
        lda #CR
        jsr CHROUT

        lda #<kbd_buf
        ldx #>kbd_buf
        jsr ConvDec16
        bcs GetWriteParams   ; Try again if error (number too big)

; Save entered value into nSectors:
        sta nSectors
        stx nSectors+1
        ora nSectors+1  ; cheeky check for zero..
        beq GetWriteParams   ; Try again if zero entered

; Get the filename:
@get_fname:
        lda #CR
        jsr CHROUT

        lda #<FileName_prompt
        ldx #>FileName_prompt
        jsr StrOut
        lda #<kbd_buf
        ldx #>kbd_buf
        jsr GetLineInput
        bcs @exit_esc        ; ESC pressed...

        cpy #0               ; Just RETURN entered (default)?
        bne @exit            ; Taken if NOT

; Enter the default value for fname:
        lda #<DEFAULT_FNAME
        sta MemPtr
        lda #>DEFAULT_FNAME
        sta MemPtr+1

        ldy #0
@fname_copy:
        lda (MemPtr),y
        beq @cont
        sta kbd_buf,y
        iny
        bra @fname_copy

@cont:
        sta kbd_buf,y        ; Null-terminate the string (a-reg has null)

        lda #CR
        jsr CHROUT      

@exit:
        clc
        rts

@exit_esc:
        sec
        rts

    .include "sec_utils.asm"


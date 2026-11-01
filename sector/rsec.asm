;---------------------------------------------------------------------------------------------
; rsec.asm - Read Sector Utility
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
AuxsZP:             .res 2    ; The auxs serial driver uses $22, so reserve it
MemPtr:             .res 2    ; 2 bytes
MemPtr1:            .res 2    ; 2 bytes
MemPtr2:            .res 2    ; 2 bytes - used by higher-level  functions
SecPtrLow:          .res 2    ; Points to sector_buf ($000..$0FF)
SecPtrHigh:         .res 2    ; Points to sector_buf ($100..$1FF)
scratch0:           .res 2
scratch1:           .res 2
nSectors:           .res 2    ; Number of sectors
CurSector:          .res 2    ; Current sector
SectorCS:           .res 2    ; Sector checksum
read_method_flag:   .res 1    ; Read method: $00=CHRIN $80=MACPTR
EOF_flag:           .res 1   ; $FF = read file EOF reached
bytes_read:         .res 2   ; ReadSector (should be $200) on return
bytes_checked:      .res 2   ; CompareSector - counts bytes checked
byte_index:         .res 2   ; CompareSectors
wbyte:              .res 1   ; Write buffer byte in CompareSectors
rbyte:              .res 1   ; Read buffer byte in CompareSectors
compare_errors:     .res 2   ; Number of compare errors in a sector
compare_hdr_flag:   .res 2   ; 0 = not written, $FF = written
buf_ptr:            .res 2   ; Buffer used by GetLineInput
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

        lda #<HelloReadStr
        ldx #>HelloReadStr
        jsr StrOut

        lda #<Input_help_msg
        ldx #>Input_help_msg
        jsr StrOut

        jsr GetReadParams
        bcs @exit               ; ESC pressed, so exit.

        jsr ReviewReadParams
        bcs @exit               ; ESC pressed or "no" selected, so exit.

        jsr OpenFileRead
        bcs @exit               ; Taken if file open failed

        jsr OpenLogFileWrite
        bcs @exit               ; Taken if file open failed


@Read_sectors:

        stz CurSector
        stz CurSector+1
        stz EOF_flag

        lda #<reading_msg
        ldx #>reading_msg
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
        bit read_method_flag
        bpl @method_chrin

        jsr ReadSector_MACPTR
        bra @read_common

@method_chrin:
        jsr ReadSector_CHRIN
@read_common:
        bcs @exit_error         ; Taken if something went wrong

; MACPTR NOTE:
;   If the file is a multiple of 512 bytes, MACPTR returns the last sector
;   WITHOUT EOF being set. On the NEXT call it returns zero bytes read and
;   EOF set. For simplicity here, we will interpret bytes_read = 0 as EOF.
;   Ideally we'd also check EOF (we can't check EOF with this logic because
;   CHRIN and most of the time MACPTR set EOF when the last sector is
;   sill in play and should be compared).

        lda bytes_read          ; See MACPTR NOTE above.
        ora bytes_read+1
        beq @done

        jsr CreateSector        ; Make an exemplar sector using CurSector
        jsr CompareSectors      ; Logs any errors
        lda #'.'                ; Good sector indicator
        bcc @compare_ok
        lda #'x'                ; Bad sector indicator
@compare_ok:
        jsr CHROUT
        inc CurSector
        bne @check_done
        inc CurSector+1

@check_done:
        bit EOF_flag
        bpl @next_sector

@done:
        lda #CR
        jsr CHROUT

@exit_close:
        jsr CloseLogFileWrite
        jsr CloseFileRead

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

@exit_error:
        lda #<read_err_msg0
        ldx #>read_err_msg0
        jsr StrOut
        lda CurSector
        ldx CurSector+1
        jsr WordOut
        lda #<read_err_msg1
        ldx #>read_err_msg1
        jsr StrOut
        bra @exit_close

;-----------------------------------------------------------
; Log_init - Call PRIOR to sector read 
;      Initializes variables for Log
;
; On Entry: * CurSector set to the current sector number
;           * LOG_FILE_LFN is open for writing
;           * CHKOUT set to LOG_FILE_LFN
;
; On Exit:  Writes the header to the log file
;
; Uses: (zp) byte_index, wbyte, rbyte, compare_errors
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
Log_init:

        stz compare_errors
        stz compare_errors+1

        stz compare_hdr_flag        ; 0 = not written, $FF = written

        rts


;-----------------------------------------------------------
; Log_header - Sends the sector compare header to the
;              log file the *FIRST* time it is called.
;
; On Entry: n/a
; On Exit:  sets compare_hdr_flag 
;
; Uses: (zp) compare_hdr_flag
;-----------------------------------------------------------
Log_header:

        bit compare_hdr_flag    ; Header previously written?
        bmi @exit               ; Taken if so

        stz compare_hdr_flag
        dec compare_hdr_flag    ; Set the flag

        lda #<log_header_msg0   ; Sector number
        ldx #>log_header_msg0
        jsr StrOut
        lda CurSector
        ldx CurSector+1
        jsr WordOut

        lda #CR
        jsr CHROUT

@exit:
        rts

;-----------------------------------------------------------
; Log_size - Check for a sector size error and writes in
;            the log file if it is found.
;
; On Entry: n/a
; On Exit:  n/a
;
; Uses: (zp) bytes_read
; Notes: Calls Log_header to write a header in case this
;        is the first error written for a sector.
;-----------------------------------------------------------
Log_size:
       
; Report if the sector size was wrong:

        lda bytes_read
        cmp #<SECTOR_SIZE
        bne @size_error
        lda bytes_read+1
        cmp #>SECTOR_SIZE
        beq @exit               ; Taken if size is OK (exit)

@size_error:
        jsr Log_header          ; Will write a header if needed

        lda #<sector_size_err0
        ldx #>sector_size_err0
        jsr StrOut

; Print bytes_read in decimal. Set up call to Hex16Dec:
        lda #<str_buf
        sta MemPtr
        lda #>str_buf
        sta MemPtr+1
        lda bytes_read
        ldx bytes_read+1
        jsr Hex16Dec

        lda #<str_buf           ; Show compare_errors in decimal
        ldx #>str_buf
        jsr StrOut

        lda #<sector_size_err1
        ldx #>sector_size_err1
        jsr StrOut

; Print SECTOR_SIZE in decimal. StrOut uses MemPtr.
        lda #<str_buf
        sta MemPtr
        lda #>str_buf
        sta MemPtr+1
        lda #<SECTOR_SIZE
        ldx #>SECTOR_SIZE
        jsr Hex16Dec

        lda #<str_buf           ; Show compare_errors in decimal
        ldx #>str_buf
        jsr StrOut

        lda #<sector_size_err2
        ldx #>sector_size_err2
        jsr StrOut

@exit:
        rts
        
;-----------------------------------------------------------
; Log_error 
;       Reports an error from CompareSectors
;
; On Entry: * CurSector set to the current sector number
;           * byte_index set to the current byte within
;             the sector buffer
;           * wbyte and rbyte are the bytes at byte_index
;           * LOG_FILE_LFN is open for writing
;           * CHKOUT set to LOG_FILE_LFN
;
; On Exit:  Displays appropriate message
;           Increments compare_errors
;           All regs and variables are preserved
;
; Uses: (zp) byte_index, wbyte, rbyte, compare_errors
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
Log_error:
        pha
        phx
        phy

        jsr Log_header

        inc compare_errors
        bne @no_carry
        inc compare_errors+1
@no_carry:

;   $xxx: $xx -> $yy

        lda #<sector_msg0
        ldx #>sector_msg0
        jsr StrOut

        lda byte_index
        ldx byte_index+1
        jsr Hex3Out

        lda #<sector_msg1
        ldx #>sector_msg1
        jsr StrOut

        lda wbyte
        jsr ByteOut

        lda #<sector_msg2
        ldx #>sector_msg2
        jsr StrOut

        lda rbyte
        jsr ByteOut

        lda #<sector_msg3
        ldx #>sector_msg3
        jsr StrOut

        ply
        plx
        pla
        rts

;-----------------------------------------------------------
; Log_post - Call AFTER sector read 
;      Writes summary for the current sector to log file
;
; On Entry: * CurSector set to the current sector number
;           * LOG_FILE_LFN is open for writing
;           * CHKOUT set to LOG_FILE_LFN
;
; On Exit:  Writes the summary to the log file
;
; Uses: (zp) byte_index, wbyte, rbyte, compare_errors
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
Log_post:

        lda compare_errors
        ora compare_errors+1
        beq @exit               ; Taken if compare_errors is zero

; Print the number of errors:
        lda #<log_errors_msg0   ; Just a space before the number.
        ldx #>log_errors_msg0
        jsr StrOut    

; Set up call to Hex16Dec:
        lda #<str_buf
        sta MemPtr
        lda #>str_buf
        sta MemPtr+1
        lda compare_errors
        ldx compare_errors+1
        jsr Hex16Dec

        lda #<str_buf           ; Show compare_errors in decimal
        ldx #>str_buf
        jsr StrOut

        lda compare_errors      ; Is it one error?
        cmp #1
        bne @errors_msg         ; Taken if NOT
        lda compare_errors+1
        bne @errors_msg         ; Taken if NOT

        lda #<log_errors_msgx   ; Singular error message
        ldx #>log_errors_msgx
        bra @cont

@errors_msg:
        lda #<log_errors_msg1
        ldx #>log_errors_msg1
@cont:
        jsr StrOut

        lda #<log_trailer_msg0  ; Make some more space
        ldx #>log_trailer_msg0
        jsr StrOut

@exit:
        rts

;-----------------------------------------------------------
; CompareSectors 
;       Compares an exemplar sector in write_sector_buf with
;       the sector in read_sector_buf and calls Log
;       if there are errors.
;
;       It only compares "bytes_read" bytes of the buffer.
;
;
; On Entry: CurSector is the "expected" sector number.
;           write_sector_buf contains a sector created by CreateSector
;           read_sector_buf contains a sector under scrutiny
;
; On Exit:  C=0 - sectors match
;           C=1 - sectors don't match (Log was called)
;
; Uses: (zp) byte_index, wbyte, rbyte
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
CompareSectors:
        stz byte_index
        stz byte_index+1
        stz bytes_checked
        stz bytes_checked+1

; Prep the log file to receive error reports:

        ldx #LOG_FILE_LFN
        jsr CHKOUT
        
        jsr Log_init

; Is there anything to check?
        lda bytes_read
        ora bytes_read+1
        beq @wrap_up            ; Don't do any comparisons

; Compare the sector in two chunks:

       ldy #0                  ; Index
@next0:
        sty byte_index          ; Keep the buffer array index LSB in sync
        lda write_sector_buf,y
        sta wbyte
        lda read_sector_buf,y 
        sta rbyte
        lda wbyte
        cmp rbyte                ; Are they the same?
        beq @good0               ; Taken if so
        jsr Log_error            ; Bytes are NOT the same.
@good0:
        iny
; See if we have reached bytes_read:
        lda bytes_read+1        ; The index is advanced by 1, so compare with bytes_read is valid
        cmp byte_index+1
        bne @not_done0
        cpy bytes_read
        beq @wrap_up             ; Taken if bytes_read bytes have been compared

@not_done0:        
        cpy #0
        bne @next0

        inc byte_index+1        ; Keep the buffer array index MSB in sync

; Check for the case where bytes_read = $100:
; (The check in the lower buffer loop won't catch it because the MSB of byte_index isn't incremented until the loop exits)

        lda bytes_read
        bne @upper_buffer       ; Not $100
        lda bytes_read+1
        cmp #$1                 ; $100?
        beq @wrap_up            ; Taken if so

@upper_buffer:        

       ldy #0                   ; Index
@next1:
        sty byte_index          ; Keep the buffer array index LSB in sync
        lda write_sector_buf+$100,y
        sta wbyte
        lda read_sector_buf+$100,y 
        sta rbyte
        lda wbyte
        cmp rbyte               ; Are they the same?
        beq @good1              ; Taken if so
        jsr Log_error           ; Bytes are NOT the same.
@good1:
        iny
; See if we have reached bytes_read:
        lda bytes_read+1        ; The index is advanced by 1, so compare with bytes_read is valid
        cmp byte_index+1
        bne @not_done1
        cpy bytes_read
        beq @wrap_up             ; Taken if bytes_read bytes have been compared

@not_done1:        
        cpy #0
        bne @next1

@wrap_up:
        lda compare_errors
        ldx compare_errors+1

        jsr Log_size
        jsr Log_post
        jsr CLRCHN

        lda compare_errors
        ora compare_errors+1
        bne @exit_err                   ; Taken if compare_errors is not zero

@exit_OK:
        clc
        rts

; There were compare  errors in this branch
@exit_err:
        sec     
        rts

;-----------------------------------------------------------
; ReadSector_MACPTR
;       Read a sector into read_sector_buf from the open file
;       using MACPTR (bulk read)
;
; On Entry: SECTOR_FILE_LFN is open for read
;
; On Exit:  C=0 - Sector was read successfully 
;           EOF_flag = $FF if EOF was detected (this is NOT an error)
;           bytes_read = number of bytes read
;
;           C=1 - Sector read failed
;           A-reg has READST code if fail
;;          bytes_read = number of bytes read
;
; Uses: (zp) bytes_read, read_sector_buf
;
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
ReadSector_MACPTR:

        stz bytes_read
        stz bytes_read+1

        ldx #SECTOR_FILE_LFN
        jsr CHKIN
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)


; Use MACPTR to read 512 bytes:
        ldx #<read_sector_buf
        ldy #>read_sector_buf
        lda #0                  ; Read up to 512 bytes
        clc                     ; We want destination address incremented
        jsr MACPTR              ; Read UP TO 512 bytes...
        bcs @exit_err           ; Not supported

; X,Y contain the number of bytes read:
        stx bytes_read
        sty bytes_read+1

; Are we at EOF?

        jsr READST              ; READST
        and #READST_EOF         ; EOF?
        bne @exit_EOF           ; Taken if so... 

; Success exit:
@exit_OK:
        jsr CLRCHN
        clc
        rts

@exit_EOF:
        dec EOF_flag    ; Set EOF flag
        bra @exit_OK

; CHKIN error, a-reg has READST code:
@exit_err:
        pha
        jsr CLRCHN
        pla
        sec     
        rts

;-----------------------------------------------------------
; ReadSector_CHRIN
;       Read a sector into read_sector_buf from the open file
;       using CHRIN (character at a time)
;
; On Entry: SECTOR_FILE_LFN is open for read
;
; On Exit:  C=0 - Sector was read successfully 
;           EOF_flag = $FF if EOF was detected (this is NOT an error)
;           bytes_read = number of bytes read
;
;           C=1 - Sector read failed
;           A-reg has READST code if fail
;;          bytes_read = number of bytes read
;
; Uses: (zp) bytes_read, read_sector_buf
;
; Note: this code assumes that SECTOR_SIZE is 512
;-----------------------------------------------------------
ReadSector_CHRIN:

        stz bytes_read
        stz bytes_read+1

        ldx #SECTOR_FILE_LFN
        jsr CHKIN
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)

; Read the sector in two chunks:

       ldy #0                  ; Index
@next0:
        inc bytes_read
        bne @skip0
        inc bytes_read+1
@skip0:
        jsr CHRIN               ; y reg preserved
        sta read_sector_buf,y   ; Save the byte in the low half of the sector buffer
        jsr READST              ; READST
        and #READST_EOF         ; EOF?
        bne @exit_EOF           ; Taken if so...
        iny
        bne @next0


       ldy #0                        ; Index
@next1:
        inc bytes_read
        bne @skip1
        inc bytes_read+1
@skip1:  
        jsr CHRIN                    ; y reg preserved
        sta read_sector_buf+$100,y   ; Save the byte in the high half of the sector buffer
        jsr READST              ; READST
        and #READST_EOF         ; EOF?
        bne @exit_EOF           ; Taken if so... 
    
        iny
        bne @next1

; Success exit:
@exit_OK:
        jsr CLRCHN
        clc
        rts

@exit_EOF:
        dec EOF_flag    ; Set EOF flag
        bra @exit_OK

; CHKIN error, a-reg has READST code:
@exit_err:
        pha
        jsr CLRCHN
        pla
        sec     
        rts

;-------------------------------------------------------------
; CloseFileRead - Close the file
;
; On Entry: n/a
; On Exit:  n/a
;
; Note: we could call READST to get the status, but we don't.
;-------------------------------------------------------------

CloseFileRead:

        lda #SECTOR_FILE_LFN  ; Close the sector file   
        jsr CLOSE
        rts

;-----------------------------------------------------------
; OpenFileRead - Open the file for read
;
; On Entry: n/a
; On Exit:  C=0 - File is open for read
;           C=1 - File open failed (e.g. file doesn't exist)
;           A-reg has READST code if open fail
;           or 0 if file doesn't exist
;              
;-----------------------------------------------------------
OpenFileRead:

; Set up for filename StrLen:
        lda #<fname_buf      ; Get filename length
        ldx #>fname_buf
        jsr StrLen         ; y-reg = length

; Set up for FileExists is a bit different:
        tya                ; a-reg = fname length
        ldx #<fname_buf
        ldy #>fname_buf

;   On Exit:  C = 0 - File exists
;                 1 - File does NOT exist
        jsr FileExists
        bcc @open_file    ; Taken if it exists

; File does NOT exist, so issue error message and exit:

        lda #<nofile_msg
        ldx #>nofile_msg
        jsr StrOut
        lda #<fname_buf
        ldx #>fname_buf
        jsr StrOut
        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT
        bra @exit_nofile

@open_file:

; Set up for the SETNAM call:

        lda #<fname_buf      ; Get filename length
        ldx #>fname_buf
        jsr StrLen         ; y-reg = length

; Set up for SETNAM is a bit different:
        tya                ; a-reg = fname length
        ldx #<fname_buf
        ldy #>fname_buf
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

; File not found:
@exit_nofile:
        lda #0
        sec
        rts

; OPEN error, a-reg has READST code:
@exit_err:
        sec     
        rts

;-----------------------------------------------------------
; ReviewReadParams - Confirm read parameters
;
; On Entry: n/a
; On Exit:  C=0 - read params confirmed
;           C=1 - ESC was entered, exit request
;-----------------------------------------------------------
ReviewReadParams:
        lda #<ReadMethod_review
        ldx #>ReadMethod_review
        jsr StrOut

; Selected the read method display text:
        bit read_method_flag
        bpl @method_chrin

        lda #<ReadMethod_MACPTR
        ldx #>ReadMethod_MACPTR
        bra @common

@method_chrin:
        lda #<ReadMethod_CHRIN
        ldx #>ReadMethod_CHRIN

@common:
        jsr StrOut

        lda #CR
        jsr CHROUT

; Confirm data file name:
        lda #<FileName_review2
        ldx #>FileName_review2
        jsr StrOut
 
        lda #<fname_buf   ; Show the data file name
        ldx #>fname_buf
        jsr StrOut
        lda #CR
        jsr CHROUT

;  Confirm log file name:

        lda #<LogFileName_review
        ldx #>LogFileName_review
        jsr StrOut
 
        lda #<log_fname_buf   ; Show the long file name
        ldx #>log_fname_buf
        jsr StrOut
        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT 

; Confirm run params with user:

        lda #<YN_prompt ; Confirm with user...
        ldx #>YN_prompt
        jsr StrOut
        jsr GetYN

; Give a little space...
        php
        pha
        lda #CR
        jsr CHROUT
;        lda #CR
;        jsr CHROUT
        pla
        plp

        bcs @exit_esc      ; Taken if ESC pressed
        cmp #PETSCII_N     ; Rejected?
        beq @exit_esc      ; Taken if so

        lda #CR
        jsr CHROUT
        lda #CR
        jsr CHROUT

@exit_OK:
        clc
        rts

; For ESC or "no" entered:
@exit_esc:
        sec
        rts

;-----------------------------------------------------------
; GetReadParams - Prompt for read parameters
;
; On Entry: n/a
; On Exit:  C=0 - read params are set
;           C=1 - ESC was entered, exit request
;-----------------------------------------------------------
GetReadParams:

        stz read_method_flag    ; Set to CHRIN

        lda #<ReadMethod_prompt
        ldx #>ReadMethod_prompt
        jsr StrOut
        lda #<kbd_buf
        ldx #>kbd_buf
        jsr GetLineInput
        php
        lda #CR
        jsr CHROUT
        plp
        bcc @not_esc         ; Taken if no ESC
        jmp @exit_esc        ; Taken if ESC pressed

@not_esc:
        cpy #0               ; RETURN entered?
        beq @set_macptr      ; Taken if so
        cpy #1               ; Just one character entered?
        bne GetReadParams    ; Taken if not (try again)

; Determine the read method selected (CHRIN is already set)
        lda kbd_buf
        and #$5F             ; Shift UPPER characters to PETSCII
        cmp #PETSCII_C       ; CHRIN?
        beq @get_fname       ; Taken if so (CHRIN is already set)
        cmp  #PETSCII_M      ; MACPTR?
        bne GetReadParams    ; Taken if NOT (error, so try again)

@set_macptr:
        lda #$80
        sta read_method_flag ; Set to MACPTR

; Get the data file name:
@get_fname:
        lda #CR
        jsr CHROUT

        lda #<FileName_prompt
        ldx #>FileName_prompt
        jsr StrOut
        lda #<fname_buf
        ldx #>fname_buf
        jsr GetLineInput
        bcs @exit_esc        ; ESC pressed...

        cpy #0               ; Just RETURN entered (default)?
        bne @get_log_fname   ; Taken if NOT

; Enter the default value for fname:
        lda #<DEFAULT_FNAME
        sta MemPtr
        lda #>DEFAULT_FNAME
        sta MemPtr+1

        ldy #0
@fname_copy:
        lda (MemPtr),y
        beq @cont0
        sta fname_buf,y
        iny
        bra @fname_copy

@cont0:
        sta fname_buf,y        ; Null-terminate the string (a-reg has null)

        lda #CR
        jsr CHROUT      

; Get the log file name:
@get_log_fname:
        lda #<LogFileName_prompt
        ldx #>LogFileName_prompt
        jsr StrOut
        lda #<log_fname_buf
        ldx #>log_fname_buf
        jsr GetLineInput
        bcs @exit_esc        ; ESC pressed...

        cpy #0               ; Just RETURN entered (default)?
        bne @exit            ; Taken if NOT

; Enter the default value for log_fname:
        lda #<DEFAULT_LOG_FNAME
        sta MemPtr
        lda #>DEFAULT_LOG_FNAME
        sta MemPtr+1

        ldy #0
@log_fname_copy:
        lda (MemPtr),y
        beq @cont1
        sta log_fname_buf,y
        iny
        bra @log_fname_copy

@cont1:
        sta log_fname_buf,y        ; Null-terminate the string (a-reg has null)

        lda #CR
        jsr CHROUT      

@exit:
        clc
        rts

@exit_esc:
        sec
        rts



;-------------------------------------------------------------
; CloseLogFileWrite - Close the file
;
; On Entry: n/a
; On Exit:  n/a
;
; Note: we could call READST to get the status, but we don't.
;-------------------------------------------------------------

CloseLogFileWrite:

        lda #LOG_FILE_LFN  ; Close the log file
        jsr CLOSE
        rts

;-----------------------------------------------------------
; OpenLogFileWrite - Open the log file for writing
;
; On Entry: n/a
; On Exit:  C=0 - File is open for writing
;           C=1 - File open failed or overwrite was denied
;           A-reg has READST code if open fail
;           or 0 if overwrite was denied
;              
;-----------------------------------------------------------
OpenLogFileWrite:

; Set up for filename StrLen:
        lda #<log_fname_buf      ; Get filename length
        ldx #>log_fname_buf
        jsr StrLen         ; y-reg = length

; Set up for FileExists is a bit different:
        tya                ; a-reg = fname length
        ldx #<log_fname_buf
        ldy #>log_fname_buf

;   On Exit:  C = 0 - File exists
;                 1 - File does NOT exist
        jsr FileExists
        bcs @prep_log_fname    ; Taken if it does NOT exist (skip overwrite prompt)

; File exists, so see if overwrite is OK with the user:

        lda #<overwrite_msgL    ; msgL for Log.    
        ldx #>overwrite_msgL
        jsr StrOut
        lda #<log_fname_buf
        ldx #>log_fname_buf
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

; Prepare the filename by adding the overwrite string at the beginning and the mode string at the end.
@prep_log_fname:
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

; Copy the log file name to the buffer after the prefix
; (y-reg points to the end of the string in the strbuf buffer)

       ldx     #0
@next1:
        lda     log_fname_buf,x
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

        lda #LOG_FILE_LFN       ; Logical file number
        ldx #8                  ; Device number (always 8)
        tay                     ; Secondary is LFN

        jsr SETLFS              ; SETLFS - A-logical file number, X-device (8), y secondary (no return value or flag)
        jsr OPEN                ; OPEN (no params), C=1 on error
        jsr READST              ; READST
        cmp #0                  ; Error?
        bne @exit_err           ; Taken if error (A-reg has READST return)

        ldx #LOG_FILE_LFN
        jsr CHKOUT

; Write data file name to log file:
        lda #<log_file_msg0     ; Data file name.
        ldx #>log_file_msg0
        jsr StrOut
        lda #<fname_buf
        ldx #>fname_buf
        jsr StrOut
        lda #<log_file_msg1
        ldx #>log_file_msg1
        jsr StrOut
        
        jsr CLRCHN

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

    .include "sec_utils.asm"

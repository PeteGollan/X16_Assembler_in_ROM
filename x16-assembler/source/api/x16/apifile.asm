; ************************************************************************************************
;
;       Name :      apifile.asm
;       Purpose :   API Open/Read/Close
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       March 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************

; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                 Open a source file or include file (TAOpen)
;                 Open/close an Object file (ObjOpen/ObjClose)
;                 Open/close a List file (ListOpen/ListClose)
;
; ************************************************************************************************

;--------------------------------------------------------------------------------------------------
; Table of file I/O buffer startimg page addresses, zero-based, offset by SRC_START_LFN.
; Each buffer is 512 bytes (2 pages).
;
; Notes: These buffers *MUST* start on an even page number and step by 2 pages.
;        If these are moved, make sure that FARCALL_RAM_TABLE2 is updated.
;--------------------------------------------------------------------------------------------------

BufferPageTable:
        .byte $B2      ; LFN  6 (asm source)
        .byte $B4      ; LFN  7 (include/.binary)
        .byte $B6      ; LFN  8 (include/.binary)
        .byte $B8      ; LFN  9 (include/.binary)
        .byte $BA      ; LFN 10 (include/.binary)
        .byte $BC      ; LFN 11 (include/.binary) or LIST/OBJ
        .byte $BE      ; LFN 12 (include/.binary) or LIST/OBJ

;---------------------------------------------------------------------------------------------------
; TAOpen
;
; On entry: X,Y = pointer to file name or NULL to use default.
; On exit : C=0 if success and A-reg=LFN
;           C=1 if failed and A-reg=error code (currently AXERRNotFound or AXERRTooManyFiles)
;---------------------------------------------------------------------------------------------------
TAOpen: 

; XY = zero terminated filename pointer

; OPEN cannot detect "too many open files". Prior to trying to open a file, check if
; we can open another file and if not, return the error code in the A-reg and C=1:

        lda nFilesOpen
        cmp #OPEN_FILES_MAX     ; Can we open another file?
        bne @nfiles_ok          ; Taken if so

; Too many files opens, so indicate error and exit:
        lda  #AXERRTooManyFiles ; Return error instead of LFN
        sec                     ; Indicate error
        rts

@nfiles_ok:

; OPEN cannot detect a non-existent file. Prior to trying to open a file,
; check if it exists and if not, return a zero LFN in the A-reg and carry set to indicate
; file-not-found.

        jsr StrLen_XY           ; Get the filename length in A-reg
        jsr FileExists          ; All regs preserved
        bcc @file_ok            ; Taken if the file exists

; The file doesn't exist, so indicate error and exit:
        lda  #AXERRNotFound     ; Return error instead of LFN
        sec                     ; Indicate error
        rts

@file_ok:

        stz TAIsEOF                     ; reset EOF flag.
        inc nFilesOpen                  ; Bump the number of open files

; Set up for the SETNAM call
; A-reg = file name length from the StrLen_XY call above
; X,Y = pointer to file name

        jsr FarSETNAM           ; SETNAM (no return value or flag)
        inc TAHandleTracker
        lda TAHandleTracker     ; Fetch LFN
        ldx #8                  ; Device number (always 8)
        tay                     ; Secondary is same as LFN
        jsr FarSETLFS           ; set LFS - A=logical file number TAHandleTracker, X is device number (8), Y is secondary (LFN)

        jsr FarOPEN             ; OPEN - C set on error (but NOT if the file doesn't exist)      
        jsr FarREADST           ; READST
        adc #$FF                ; set CS on error (A != 0)
        bcs @exit1              ; Taken if OPEN error

        ldx TAHandleTracker     ; Fetch LFN
        jsr FillReadBuffer 

; This is the success exit.
@exit:

        lda TAHandleTracker     ; Return LFN
        clc
@exit1:
        rts

; ************************************************************************************************
;
;                                       Close file handle in X
;
; ************************************************************************************************

TAClose:

        txa
        jsr FarCLOSE            ; CLOSE
        dec TAHandleTracker
        dec nFilesOpen  
        clc
        rts     
;-------------------------------------------------------------------------
; FillReadBuffer
;       Fills a 512-byte read buffer from an open file for a given LFN
;
;   Prior   : File is open for reading.
;   On Entry: X-reg = LFN
;   On Exit:  Read buffer is filled and data structures initialized.
;
; Uses ZP: Temp0
;-------------------------------------------------------------------------
FillReadBuffer:
        stx Temp0                               ; Save LFN
        stz TAIsEOF                             ; Clear TAReadChar's EOF flag
        stz EOF_flag_table-SRC_START_LFN,x      ; Clear the EOF flag by default
        lda BufferPageTable-SRC_START_LFN,x     ; Get the table page number
        sta CurReadBufferPtr+1                  ; Initialize the MSB of the read buffer pointer (ZP)
        stz CurReadBufferPtr                    ; Initialize the LSB of the read buffer pointer (ZP)
        stz index_table_LSB-SRC_START_LFN,x     ; Clear the index LSB
        stz index_table_MSB-SRC_START_LFN,x     ; Clear the index MSB

; X-reg contains LFN:

;*** Call CHKIN for every buffer.
;        cpx CurCHK_LFN          ; Are we already set for this LFN?
;        beq @CHKIN_OK           ; Taken if so
        stx CurCHK_LFN          ; Saved here as FarCHKIN will destroy it
        jsr FarCHKIN            ; All regs destroyed (not needed at this point)

@CHKIN_OK:

; Use MACPTR to buffer up to 512 bytes (2 pages)
        
        ldx CurReadBufferPtr   ; XY point to 512 byte read buffer
        ldy CurReadBufferPtr+1
        lda #0                  ; Read up to 512 bytes
        clc                     ; We want destination address incremented
        jsr Far2MACPTR          ; Read UP TO 512 bytes...
        bcs @error_exit         ; Some kind of read error

; If XY (read size) are zero here, it means that we are at EOF with no new bytes in the buffer:
        cpx #0                  ; X zero?
        bne @set_EOB_index      ; Taken if NOT
        cpy #0                  ; X and Y zero?
        bne @set_EOB_index      ; Taken if NOT

; The read buffer is empty, so bypass the delayed EOF system:
        dec TAIsEOF             ; TAReadChar will exit immediately, without checking the buffer
        bra @exit

; X,Y contain the number of bytes read. Save this as end-of-buffer index (EOB)
@set_EOB_index:
        txa                     ; A-reg = bytes read LSB
        ldx Temp0               ; Fetch our LFN
        sec                     ; Subtract 1 from the count so it becomes an index of the last character
        sbc #1
        sta EOB_index_table_LSB-SRC_START_LFN,x     ; Save LSB as end-of-buffer index (EOB)
        tya
        sbc #0
        sta EOB_index_table_MSB-SRC_START_LFN,x     ; Save MSB as end-of-buffer index (EOB)

; Is this EOB also end-of-file (EOF)?
        jsr FarREADST            ; A-reg=status, X,Y preserved
        and #64                  ; EOF with this char?
        bne @eof_exit            ; Taken if so

@exit:
        clc
        rts

; Mark the EOF byte in the buffer. This is NOT an error.
@eof_exit:
        ldx Temp0                            ; Get LFN
        dec EOF_flag_table-SRC_START_LFN,x 
        clc
        rts

@error_exit:
        lda #AXERRSourceFile     ; Return source file read error
        sec
        rts

; ************************************************************************************************
;
;                               Read a character from the buffer for LFN X.
;
; Read buffers are up to 512 bytes. They are stored in FIO_RAM_BANK
; EOB_index_table_LSB and EOB_index_table_MSB point at the last character in the buffer
; If EOF_flag_table is set, it means that EOB_index_table also points at the last character in the file
; ************************************************************************************************

TAReadChar:

        lda TAIsEOF                     ; The last call to TAReadChar reached EOF?
        bne @TAFail                     ; Taken if so

; X-reg has LFN. Set up CurReadBufferPtr to point at our next character:
        lda index_table_LSB-SRC_START_LFN,x
        sta CurReadBufferPtr                    ; Initialize the LSB of the read buffer pointer (ZP)
        lda BufferPageTable-SRC_START_LFN,x     ; Get the table page number
        ora index_table_MSB-SRC_START_LFN,x     ; Use a shortcut to add the MSB (0 or 1) of the index to our buffer page MSB
        sta CurReadBufferPtr+1                  ; Initialize the MSB of the read buffer pointer (ZP)

        stz TAReadCharEOB_flag                  ; Clear EOB flag

; Is *this* character EOB?
        lda index_table_LSB-SRC_START_LFN,x
        cmp EOB_index_table_LSB-SRC_START_LFN,x ; LSBs match?
        bne @fetch_char                         ; Taken if not
        lda index_table_MSB-SRC_START_LFN,x
        cmp EOB_index_table_MSB-SRC_START_LFN,x ; MSBs match?
        bne @fetch_char                         ; Taken if not

; EOB detected, so set the flag and check EOF:
        dec TAReadCharEOB_flag                  ; EOB detected, so set the flag.
        lda EOF_flag_table-SRC_START_LFN,x      ; Is the EOF flag set for this buffer?
        beq @fetch_char                         ; taken if not
        dec TAIsEOF                             ; Set the EOF flag for the NEXT call... we still send the character.

@fetch_char:
        ldy #0                          ; Y-reg is NOT used to index
        lda (CurReadBufferPtr),y        ; Fetch the character (CurReadBufferPtr has the entire addr)

; Bump the buffer index. A-reg has char read and X-reg has LFN:

        inc index_table_LSB-SRC_START_LFN,x     ; LSB of index
        bne @Check_EOB
        inc index_table_MSB-SRC_START_LFN,x     ; MSB of index

@Check_EOB:
        ldy TAReadCharEOB_flag                  ; Are we at EOB?
        beq @TAExit                             ; Taken if NOT (A-reg has character)

; We are at EOB, so see if we are also at EOF:
        ldy TAIsEOF                             ; Is it EOF?
        bne @TAExit                             ; Taken if so (just exit, don't refill buffer)

; EOB, so refill the buffer, while saving the last character:
        sta Temp1                    ; Save char read because we still have to return it
        jsr FillReadBuffer           ; Refill the read buffer (X-reg has LFN)
        lda Temp1                    ; Recover char so we can return it to caller
@TAExit:
        clc
        rts

@TAFail:
        stz TAIsEOF                     ; clear EOF Flag
        sec
        rts     

;-------------------------------------------------------------------------------------------------
; TAFileWriteByte -  Write a byte in A-reg to the buffer for LFN X-reg.
;
; On Entry: A-reg = byte to write, X-reg contains LFN
;
; On Exit : Returns C=1, write_error_flag is set and the error code is in write_error_code
;
; Uses    : (zp) FileWriteByteSave
;-------------------------------------------------------------------------------------------------

TAFileWriteByte:

; A-reg has byte, X-reg has LFN:

        sta FileWriteByteSave           ; Save byte to be written (we need more registers than we have!)

        ldy BufferPageTable-SRC_START_LFN,x ; Get the table page number
        sty CurWriteBufferPtr+1              ; Initialize the MSB of the write buffer pointer (ZP)
        
        ldy index_table_LSB-SRC_START_LFN,x ; Y-reg = current write index (only LSB is used for write)
        lda FileWriteByteSave           ; Fetch the char to write (zp)
        sta (CurWriteBufferPtr),y       ; Save the character
        inc index_table_LSB-SRC_START_LFN,x ; Bump the index (only LSB is used for write)   
        bne @TAExit                     ; Take if buffer is NOT full

; Save the buffer (X-reg has LFN)
        jsr SaveWriteBuffer             ; End of buffer reached, so save it (x-reg has LFN)
        bcs @TAExit_error               ; Taken if write failed (error codes al already set)

@TAExit:
        clc
        rts

; C is already set and error codes are saved
@TAExit_error:     
        rts

;-------------------------------------------------------------------------------------------------
; SaveWriteBuffer -  Save a full write buffer to an open file (interpretes an index of 0 as 256 bytes)
; FlushWriteBuffer - Save a PARTIAL write buffer to an open file (interprets an index of 0 as an empty buffer)
;
; Prior   : File is open for writing.
; On Entry: X-reg = LFN
; On Exit : Write buffer is saved and data structures are initialized
;           Returns C=1, write_error_flag is set and the error code is in write_error_code
;
; Uses ZP: Temp0
;
; This function contains a workaround for a Calypso MCIOUT bug
; * After some number of writes using MCIOUT, the Calpso driver crashes on a call to MCIOUT
; * The workaround to to always issue CHKOUT prior to MCIOUT
; * This workaround has no measureable impact on performance on stock (non-Calypso) configurations
; * The impact to Calypso configurations is impossible to measure, but it is noted that
;   Calypso generally has better I/O performance than stock.
; * If this Calypso driver bug is ever fixed, renable the check as noted below.
;-------------------------------------------------------------------------------------------------
FlushWriteBuffer:

        lda index_table_LSB-SRC_START_LFN,x ; Number of bytes to be written (only LSB is used for WRITE)
        bne SaveWriteBuffer             ; Taken if the number of bytes to write is NOT zero
        clc                             ; Nothing to save, success exit.
        rts

SaveWriteBuffer:

        stx Temp0                ; Save LFN
        
        lda BufferPageTable-SRC_START_LFN,x  ; Get the table page number
        sta CurWriteBufferPtr+1              ; Initialize the MSB of the write buffer pointer (ZP)

; X-reg contains LFN:
        cpx CurCHK_LFN          ; Are we already set for this LFN?

; Calypso bug workaround is always call CHKOUT prior to MCIOUT
;vvv *** Calypso Bug Workaround *** vvv Reenable when the bug is fixed
;***        beq _CHKOUT_OK          ; Taken if so
;^^^ *** Calypso Bug Workaround *** ^^^ Reenable when the bug is fixed

; Call CHKOUT for this LFN:        
        stx CurCHK_LFN          ; Saved here as FarCHKOUT will destroy it
        jsr FarCHKOUT           ; All regs destroyed (not needed at this point)
        jsr FarREADST           ; READST (x and y-regs are preserved)
        adc #$FF                ; set CS on error (A != 0)
        bcs @exit_error         ; Taken if error

@CHKOUT_OK:
; Use MCIOUT to write the entire buffer (256 bytes)

        ldx  Temp0                      ; Fetch LFN for index
        lda index_table_LSB-SRC_START_LFN,x ; Number of bytes to be written (0=max) (only LSB is used for WRITE)

        ldx CurWriteBufferPtr   ; XY point to data
        ldy CurWriteBufferPtr+1
        clc                     ; We want source address incremented
        jsr Far2MCIOUT
        bcs @exit_error         ; *** FOR NOW

@exit_OK:
        clc
        rts

@exit_error:
        lda #AXERRObject         ; Assume object error
        sta write_error_code

; Is the error OBJ or LIST?
        lda Temp0               ; Get the LFN
        cmp obj_LFN             ; Is it OBJ?
        beq @exit_error2
        lda #AXERRList          ; Correct it to list error
        sta write_error_code
@exit_error2:
        stz write_error_flag
        dec write_error_flag
        rts


; ************************************************************************************************
;
;                               Open an Object File
;
; ************************************************************************************************
; This is here because the farjsr calls were not accessible from the pseudo_ops directory.

ObjOpen:

; We only act on pass 1 (listing line and opening file):
        lda AXPass                   ; Which pass are we on?
        cmp #1                       ; Is this pass 1?
        beq @ObjOpenFirstPass        ; Taken if so..
        clc                         
        rts

@ObjOpenFirstPass:

        ldx AXOperandPos        
        jsr AXTGetTextString            ; file name to buffeer

        bcc @AXISyntaxGood               ; Taken if OK

; Syntax error exit:
        lda #AXERRSyntax
        sec     
        rts

@AXISyntaxGood:
        jsr AXListLine                  ; list line before expansion

        ldx #<strbuf
        ldy #>strbuf
        stx MemPtr
        sty MemPtr+1

        lda #OBJ_FILE_SET 
        and ops_flags               ; Is it already set?
        beq @AXFirstObj             ; Taken if NOT
        lda #AXERRObjDup            ; Error exit (duplicate .obj)
        sec
        rts


; See if we have enough file handles to open the file:
@AXFirstObj:
        lda nFilesOpen
        cmp #OPEN_FILES_MAX     ; Can we open another file?
        bne @nfiles_ok          ; Taken if so

; Too many files open, so indicate error and exit:
        lda  #AXERRTooManyFiles ; Return error instead of LFN
        sec                     ; Indicate error
        rts

; Determine which of the two write LFNs to use:
@nfiles_ok:
        lda #LIST_FILE_SET          ; Do we ALSO have a list file?
        and ops_flags
        beq @use_LFN_1              ; Taken if NOT

; A list file has already been defined so take the remaining write LFN:

        lda #WRITE_LFN_2            ; Take the second (lowest) write LFN
        bra @assign_write_LFN

@use_LFN_1:
        lda #WRITE_LFN_1            ; Take the first (highest) write LFN

@assign_write_LFN:
        sta obj_LFN

; This is pass 1 and the first .obj so open the file:

; Copy the "@:" (overwrite) prefix to the buffer:

       ldx     #0
       ldy     #0
@next0:
        lda     OverwriteStr,x
        sta     (MemPtr),y
        beq     @cont0          ; Taken if we loaded/saved a zero
        inx
        iny
        bne     @next0          ; Taken if not
@cont0:

; Copy the object file name to the buffer after the prefix
; (y-reg points to the end of the string in the strbuf buffer)

       ldx     #0
@next1:
        lda     AXTextParameter,x
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
        ldx #<strbuf
        ldy #>strbuf

        jsr FarSETNAM           ; SETNAM (no return value or flag)

        lda obj_LFN             ; Logical file number
        ldx #8                  ; Device number (always 8)
        tay                     ; Secondary is LFN

        jsr FarSETLFS           ; SETLFS - A-logical file number, X-device (8), y secondary (no return value or flag)
        jsr FarOPEN             ; OPEN (no params), C=1 on error
        jsr FarREADST           ; READST
        adc #$FF                ; set CS on error (A != 0)
        bcs @AXIObjectErr       ; Taken if error

; Obj file name is set and file is open:
        lda #(OBJ_FILE_SET | OBJ_FILE_OPEN)
        ora ops_flags
        sta ops_flags
        inc nFilesOpen                  ; Bump the number of open files

; Initialize the file's write buffer:
        ldx obj_LFN
        stz index_table_LSB-SRC_START_LFN,x  ; Set the initial write pointer to first byte (only LSB is used for WRITE)

        stz CurCHK_LFN  ; Invalidate the current LFN as it seems OPEN messes with it.

; Success exit:
        clc
        rts

@AXIObjectErr:
        lda     #AXERRObject
        sec     
        rts


; ************************************************************************************************
;
;                               Open a List File
;
; ************************************************************************************************
; This is here because the farjsr calls were not accessible from the pseudo_ops directory.

ListOpen:

; We only act on pass 1 (listing line and opening file):
        lda AXPass                   ; Which pass are we on?
        cmp #1                       ; Is this pass 1?
        beq @ListOpenFirstPass       ; Taken if so..
        clc                         
        rts

@ListOpenFirstPass:

        ldx AXOperandPos        
        jsr AXTGetTextString            ; file name to buffeer

        bcc @AXISyntaxGood              ; Taken if OK

; Syntax error exit:
        lda #AXERRSyntax
        sec     
        rts

@AXISyntaxGood:
        jsr AXListLine                  ; list line before expansion

        ldx #<strbuf
        ldy #>strbuf
        stx MemPtr
        sty MemPtr+1

        lda #LIST_FILE_SET 
        and ops_flags                 ; Is it already set?
        beq  @AXFirstList             ; Taken if NOT
        lda  #AXERRListDup            ; Error exit (duplicate .list)
        sec
        rts

; This is pass 1 and the first .list so open the file
; First, see if we have enough file handles to open the file:
@AXFirstList:

        lda nFilesOpen
        cmp #OPEN_FILES_MAX     ; Can we open another file?
        bne @nfiles_ok          ; Taken if so

; Too many files open, so indicate error and exit:
        lda  #AXERRTooManyFiles ; Return error instead of LFN
        sec                     ; Indicate error
        rts

; Determine which of the two write LFNs to use:
@nfiles_ok:
        lda #OBJ_FILE_SET          ; Do we ALSO have an object file?
        and ops_flags
        beq @use_LFN_1              ; Taken if NOT

; An object file has already been defined so take the remaining write LFN:

        lda #WRITE_LFN_2            ; Take the second (lowest) write LFN
        bra @assign_write_LFN

@use_LFN_1:
        lda #WRITE_LFN_1            ; Take the first (highest) write LFN

@assign_write_LFN:
        sta list_LFN


; Copy the "@:" (overwrite) prefix to the buffer:

       ldx     #0
       ldy     #0
@next0:
        lda     OverwriteStr,x
        sta     (MemPtr),y
        beq     @cont0          ; Taken if we loaded/saved a zero
        inx
        iny
        bne     @next0          ; Taken if not
@cont0:

; Copy the list file name to the buffer after the prefix
; (y-reg points to the end of the string in the strbuf buffer)

       ldx     #0
@next1:
        lda     AXTextParameter,x
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
        ldx #<strbuf
        ldy #>strbuf
        jsr FarSETNAM                        ; SETNAM (no return value or flag)

        lda list_LFN           ; Logical file number
        ldx #8                  ; Device number (always 8)
        tay
       
        jsr FarSETLFS           ; SETLFS - A-logical file number, X-device (8), y secondary (no return value or flag)
        jsr FarOPEN             ; OPEN (no params), C=1 on error
        jsr FarREADST           ; READST
        adc #$FF            ; set CS on error (A != 0)
        bcs @AXIListErr     ; Taken if error

; List file name is set and file is open:
        lda #(LIST_FILE_SET | LIST_FILE_OPEN)
        ora ops_flags
        sta ops_flags
        inc nFilesOpen                  ; Bump the number of open files

; Initialize the file's write buffer:
        ldx list_LFN
        stz index_table_LSB-SRC_START_LFN,x  ; Set the initial write pointer to first byte (only LSB is used for WRITE)
        stz CurCHK_LFN  ; Invalidate the current LFN as OPEN messes with it.

; Write text header to the list file:

        ldx #0
@next:
        lda list_file_header,x
        beq @cont
        jsr TAListChar
        inx
        bne @next
@cont:

; Now that the listing file is open, send the name of the source file and pass number:
        jsr ListPass
        bcs @AXIListErr         ; Taken if there is an issue
        jsr ListAssemblingFile
        bcs @AXIListErr         ; Taken if there is an issue

; Success exit:
        clc
        rts

@AXIListErr:
        lda     #AXERRList
        sec     
        rts



; ************************************************************************************************
;
;                              Close the Object and List Files
;
; ************************************************************************************************
; This is here because the farjsr calls were not accessible in assembler\00main.asm.
; It would have gone in AXAssemble, after both AssemblerPass calls return.

CloseFiles:

        lda #OBJ_FILE_OPEN
        and ops_flags
        beq @NotOpen1           ; Taken if NOT open

; Flush and close the object file:
        ldx obj_LFN
        jsr FlushWriteBuffer    ; Save the last bit of object
        lda obj_LFN             ; Close the Object file
        jsr FarCLOSE            ; CLOSE
        dec nFilesOpen          ; Keep track anyway

@NotOpen1:
        lda #LIST_FILE_OPEN
        and ops_flags
        beq @NotOpen2           ; Taken if NOT open
; Flush and close the list file:
        ldx list_LFN
        jsr FlushWriteBuffer    ; Save the last bit of list
        lda list_LFN            ; Close the List file
        jsr FarCLOSE            ; CLOSE
        dec nFilesOpen          ; Keep track anyway

@NotOpen2:
        rts

OverwriteStr:   .byte $40,$3A,$00       ; 64TASS is not encoding .text "@:" correctly
WriteModeStr:   .byte ",s,w",$00

; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       file.asm
;       Purpose:    Assemble a single file
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Assemble file, X,Y is file name/NULL
;
; ************************************************************************************************

AXAssembleFile:

        stz     AXLineNumber                ; reset line numbers
        stz     AXLineNumberDecimal 
        stz     AXLineNumber+1 
        stz     AXLineNumberDecimal+1

        stx TempFNameSavePtr               ; Temporarily save the file name pointer
        sty TempFNameSavePtr+1

        jsr TAOpen                  ; open the source file.
        bcc     @AXOpen_ok

; An error occured, so zero the file handle:
        ldx #0
        stx     AXFileHandle                ; OPEN error, so zero the FileHandle (how the code used to work)
        bra     @AXAFError2           
        ;

@AXOpen_ok:
        sta     AXFileHandle                ; Save the file handle
        stz     AXLastCharacter             ; no last character
        stz     AXLocalLabelID              ; reset the local label ID
        stz     AXLocalLabelID+1
        dec     AsmFileOpen_flag            ; Set flag (we set this every time a file is opened)

; OPEN succeeded, so save the file name:

        clc                     ; Set CurFNameSavePtr to next open entry
        lda CurFNameSavePtr
        adc #FNAME_SAVE_SIZE
        sta CurFNameSavePtr
        lda CurFNameSavePtr+1
        adc #0
        sta CurFNameSavePtr+1

; Copy the filename to strbuf, possibly splitting it:

        lda #MAX_ERR_FNAME_LEN
        ldx TempFNameSavePtr
        ldy TempFNameSavePtr+1
        jsr SplitStr_XY         ; Copies/Splits to strbuf

; Copy the current file name from strbuf to the FNameSaveTable entry
; pointed to by CurFnameSavePtr

        ldy #0
@FName_next:
        lda strbuf,y
        sta (CurFNameSavePtr),y
        beq @FName_cont                 ; Taken if NULL copied
        iny
        bne @FName_next

@FName_cont:

; Print "assembling file:<file>"

        jsr ListAssemblingFile
        bcc @AXMainLoop
        lda #AXERRList          ; Carry is already set
        bra @AXAFError2  

;----------------------------------------------------------
;       The main assembler loop.
;----------------------------------------------------------

@AXMainLoop:
        ;
        jsr     AXReadLine                  ; read the next line
        bcs     @AXAFError                  ; exit if problem (e.g. too long/eof)
        jsr     AXAssembleLine              ; assemble it.
        bcs     @AXAFError                  ; exit if problem there.  
        jsr     AXListLine                  ; list the line.
        bra     @AXMainLoop
        ;
        ;       Come here on error *or* EOF
        ;

@AXAFError:
; We must check write_error_flag FIRST, because in some cases the error code is NOT in the A-reg
; (it is always in write_error_code).
        bit     write_error_flag            ; Was there a low-level error?
        bpl     @AXAFError1                 ; Taken if not

        lda     write_error_code            ; Get the error code...
        bra     @AXAFError2                 ; It can't be EOF, so and handle it.

@AXAFError1:
        cmp     #AXERREOF                   ; was the error EOF, which isn't an error :)
        clc                                 ; if so don't report an error.
        beq     @AFAXCloseExit

; Handles all errors other than EOF:
@AXAFError2:
        sta     AXErrorCode                 ; save errorcode
; ca65 didn't like this way of getting the address:        
;        ldy     #AXErrorCode >> 8           ; YX = error area.
;        ldx     #AXErrorCode & $FF
        ldy     #>AXErrorCode               ; NOTE: MSB        XY is pointer to error area
        ldx     #<AXErrorCode               ; NOTE: LSB   
        jsr     TAError                     ; C=1 exit
        sec                                 ; All errors are fatal, as we have very limited capacity to display errors.
        lda AXErrorCode                     ; Return the error code

@AFAXCloseExit:
        php                                 ; save error flag and error ID
        pha

        lda AXFileHandle        ; Was it an invalid file (LFN zero)?
        beq @AXAFExit           ; Taken if so (file was not open, so skip close and CurFNamePtr decrement)

        ldx     AXFileHandle
        jsr     TAClose                 ; close the file.

; File was CLOSED, so remove the current filename:

        sec                     ; Closed current file, so set CurFNameSavePtr to previous entry
        lda CurFNameSavePtr
        sbc #FNAME_SAVE_SIZE
        sta CurFNameSavePtr
        lda CurFNameSavePtr+1
        sbc #0
        sta CurFNameSavePtr+1

; We must return the error code in A and error status in C (C=1 means error)
@AXAFExit:
        pla                                 ; restore flag/id and exit.
        plp
        rts     





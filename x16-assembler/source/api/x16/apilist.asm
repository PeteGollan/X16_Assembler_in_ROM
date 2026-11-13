; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      apilist.asm
;       Purpose :   API List Handler
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       March 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

;----------------------------------------------------------------------------
; TAListChar
;       If a listing file is being written, send character to the listing file.
;   Prior   : List file is open and list_LFN is set
;   On Entry: A-reg contains the char to list
;   On Exit : X,Y regs are preserved
;             C = 0 - success 
;             C = 1 - error writing to listing file, A-reg contains error code
;
; Note: this function has changed to receiving the character in the A-reg.
;----------------------------------------------------------------------------

TAListChar:

        phx                     ; Preserve X and Y to simplify calling
        phy
        ldx list_LFN
        jsr TAFileWriteByte
        ply
        plx
        bcs @exit_error         ; Taken if error

@exit_OK:
        clc
        rts

@exit_error:
        lda #AXERRList          ; Carry is already set
        rts

;----------------------------------------------------------------------------
; ListPass
;       If a listing file is being written, send the pass number (1 or 2)
;       to the file.
;
;   On Entry: AXPass contains the pass number.
;   On Exit : C = 0 - success 
;             C = 1 - error writing to listing file.
;
;----------------------------------------------------------------------------
ListPass:
        lda #LIST_FILE_OPEN     ; Do we have a listing file?
        and ops_flags
        bne @have_list_file
        clc
        rts                     ; Exit if not

@have_list_file:


; Write "Assembly pass " to the listing:
        ldx #0
@next0:
        lda list_pass_prefix,x
        beq @cont0
        jsr TAListChar
        inx
        bne @next0
@cont0:

        clc                     ; Send the pass number (1 or 2)
        lda #'0'
        adc AXPass
        jsr TAListChar

; Write list pass ending to the listing:
        ldx #0
@next1:
        lda list_pass_suffix,x
        beq @cont1
        jsr TAListChar
        inx
        bne @next1
@cont1:
        clc
        rts

;----------------------------------------------------------------------------
; ListResumingFile
;       If a listing file is being written, sends string to the listing file:
;       Resuming file:<file> or Resuming source:<file> (based on CurFNameSavePtr)
;
;   On Entry: CurFNameSavePtr contains a pointer to the current file name.
;   On Exit : C = 0 - success 
;             C = 1 - error writing to listing file.
;
;----------------------------------------------------------------------------
ListResumingFile:
        lda #LIST_FILE_OPEN     ; Do we have a listing file?
        and ops_flags
        bne @have_list_file
        clc
        rts                     ; Exit if not

@have_list_file:

; The first entry in the FNameSaveTable is the source file. Subsequent entries are includes.

        lda TAHandleTracker
        cmp #SRC_START_LFN      ; Is this the source file?
        bne @inc_file           ; Taken if not

; Write "resuming source:" to the listing:
        ldx #0
@next0:
        lda list_resuming_src,x
        beq @cont0
        jsr TAListChar
        inx
        bne @next0
@cont0:
        bra @cont1

@inc_file:
; Write "resuming file:" to the listing:

        ldx #0
@next1:
        lda list_resuming_file,x
        beq @cont1
        jsr TAListChar
        inx
        bne @next1
@cont1:

; Write the current filename from the FNameSaveTable to the list file:

        ldy #0                  ; filename index
@next2:
        lda (CurFNameSavePtr),y
        beq @cont2
        jsr TAListChar
        iny
        bne @next2
@cont2:

        lda #CR
        jsr TAListChar
        
        clc
        rts

;----------------------------------------------------------------------------
; ListAssemblingFile
;       If a listing file is being written, sends string to the listing file:
;       Assembling file:<file> or Assembling source:<file> (based on CurFNameSavePtr)
;
;   On Entry: CurFNameSavePtr contains a pointer to the current file name.
;   On Exit : C = 0 - success 
;             C = 1 - error writing to listing file.
;
;----------------------------------------------------------------------------
ListAssemblingFile:
        lda #LIST_FILE_OPEN     ; Do we have a listing file?
        and ops_flags
        bne @have_list_file
        clc
        rts                     ; Exit if not

@have_list_file:

; The first entry in the FNameSaveTable is the source file. Subsequent entries are includes.

        lda TAHandleTracker
        cmp #SRC_START_LFN      ; Is this the source file?
        bne @inc_file           ; Taken if not

; Write "assembling source:" to the listing:
        ldx #0
@next0:
        lda list_assembling_src,x
        beq @cont0
        jsr TAListChar
        inx
        bne @next0
@cont0:
        bra @cont1

@inc_file:
; Write "assembling file:" to the listing:

        ldx #0
@next1:
        lda list_assembling_file,x
        beq @cont1
        jsr TAListChar
        inx
        bne @next1
@cont1:

; Write the current filename from the FNameSaveTable to the list file:

        ldy #0                  ; filename index
@next2:
        lda (CurFNameSavePtr),y
        beq @cont2
        jsr TAListChar           ; This is in RAM BANK 1. X,Y preserved
        iny
        bne @next2
@cont2:

        lda #CR
        jsr TAListChar
        
        clc
        rts


;----------------------------------------------------------------------------
; ListResponseMsg
;       If a listing file is being written, sends the response/success in the
;       KERNAL_buffer to the listing file.
;
;   On Entry: KERNAL_buffer contains a null terminated string as prepared by
;             FormatResponseMsg/FormatSuccessMsg
;   On Exit : C = 0 - success 
;             C = 1 - error writing to listing file.
;
;----------------------------------------------------------------------------
ListResponseMsg:
        lda #LIST_FILE_OPEN     ; Do we have a listing file?
        and ops_flags
        bne @have_list_file
        clc
        rts                     ; Exit if not


@have_list_file:

; Write the list file trailer ("end of assembly"). This includes a CR for the response line:

        ldx #0
@next0:
        lda list_file_trailer,x
        beq @cont0
        jsr TAListChar
        inx
        bne @next0
@cont0:

; Write KERNAL_buffer in RAM  bank 0 to the list file:

        ldy #HOME_RAM_BANK
        ldx #0                  ; KERNAL_buffer index
@next1:
        stz RAM_BANK_REG        ; Select KERNAL RAM BANK.
        lda KERNAL_buffer,x
        sty RAM_BANK_REG        ; Back to our HOME_RAM_BANK
        beq @cont1
        jsr TAListChar          ; This is in RAM BANK 1. X,Y preserved
        inx
        bne @next1
@cont1:

        lda #CR
        jsr TAListChar
        
        clc
        rts




; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      apierror.asm
;       Purpose :   API Error Handler
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
;                   Handle Error, YX is address of error information
;
; ************************************************************************************************

TAError:
        stx     TATemp0                     ; save info area address
        sty     TATemp0+1


; Gather the error information for use by the exit code:

        ldy #1                          ; This records the line in the SOURCE file where the error occured...
        lda (TATemp0),y                 ; ... so the EDIT cursor can be placed on it.
        sta Last_AE_ErrorLine
        iny
        lda (TATemp0),y
        sta Last_AE_ErrorLine+1

; We only take a snapshot of the error data the FIRST time an error is detected:
        lda AE_Error_flag                   ; Already set?
        bne @skip_error_snapshot            ; Taken if so

        ldy #0
        lda (TATemp0),y                      ; Is the error code AXERRNotFound?
        cmp #AXERRNotFound
        bne @do_snapshot                     ; Taken if not

; Error AXERRNotFound requires special handling.
; If it is the asm source file (AsmFileOpen_flag = 0), we just set AE_ErrorFNamePtr to NULL and
; zero out the line numbers.
;
; If it is any other source file (AsmFileOpen_flag = 1), we defer the error if the line numbers are zero as
; it means that we are in the failed include file's stack frame. The next time this is called, we will be
; in the including file's stack frame, and the error data will be valid.

        lda AsmFileOpen_flag                 ; Asm source or include file?
        bne @include_file                    ; Taken if INCLUDE file

; Asm source, so set the error data and exit:

        ldy #0
        lda (TATemp0),y                      ; Is the error code AXERRNotFound?
        sta AE_ErrorCode
        stz AE_ErrorLine
        stz AE_ErrorLine+1
        stz AE_ErrorLineDecimal
        stz AE_ErrorLineDecimal+1

        stz AE_ErrorFNamePtr            ; File name isn't shown if ErrorLine is zero
        stz AE_ErrorFNamePtr+1
        bra @exit

@include_file:
        lda Last_AE_ErrorLine                ; AXERRNotFound, is the error line zero?
        ora Last_AE_ErrorLine+1
        beq @skip_error_snapshot             ; Taken if so... (skip snapshot this time)

@do_snapshot:
        lda #$ff
        sta AE_Error_flag                   ; Set flag so we don't check again
        ldy #0
        lda (TATemp0),y                     ; Error code
        sta AE_ErrorCode

        iny
        lda (TATemp0),y                     ; Line number LSB
        sta AE_ErrorLine
        iny
        lda (TATemp0),y                     ; Line number MSB
        sta AE_ErrorLine+1
        iny
        lda (TATemp0),y                     ; Line number BCD LSB
        sta AE_ErrorLineDecimal
        iny
        lda (TATemp0),y                     ; Line number BCD MSB
        sta AE_ErrorLineDecimal+1

        lda CurFNameSavePtr                 ; Current file name
        sta AE_ErrorFNamePtr
        lda CurFNameSavePtr+1
        sta AE_ErrorFNamePtr+1

@skip_error_snapshot:
@exit:
        sec                     ; All errors are fatal
        rts

; ************************************************************************************************
; APIGetErrorStr - Return a string for a given error code.
;
; Input: A-reg - error code (errors.inc)
; Output: X,Y - pointer to static zero-terminated error string associated with the error code
;
; ************************************************************************************************ 
APIGetErrorStr:
;***        and #$7F                  ; Mask the MS bit to form an index
        asl a                     ; x2 to form pointer table index
        tax
        lda APIErrorTable+1,x     ; Get error string pointer LSB
        tay
        lda APIErrorTable,x       ; Get error string pinter MSB
        tax
        rts

; Table of pointers to error strings, arranged in the same order as the error codes in errors.inc

APIErrorTable:
        .word ErrorStr_00  ; AXERREOF           end of file, not assembler error.
        .word ErrorStr_01  ; AXERRSyntax        general syntax error.
        .word ErrorStr_02  ; AXERRIdentifier    bad identifier, missing/too long.
        .word ErrorStr_03  ; AXERRDivZero       divide by zero.
        .word ErrorStr_04  ; AXERRRedefine      value of an identifier has changed.
        .word ErrorStr_05  ; AXERRNotFound      source file not found.
        .word ErrorStr_06  ; AXERRUndefined     undefined identifier.
        .word ErrorStr_07  ; AXERRRelative      relative branch range.
        .word ErrorStr_08  ; AXERRMode          address mode not supported
        .word ErrorStr_09  ; AXERRSize          bad expression.
        .word ErrorStr_0A  ; AXERRLength        line too long.
        .word ErrorStr_0B  ; AXERRMacroParams   too many macro parameters.
        .word ErrorStr_0C  ; AXERRParam         bad expansion parameter.
        .word ErrorStr_0D  ; AXERRMemory        out of memory.
        .word ErrorStr_0E  ; AXERRObject        object file error (open or write).
        .word ErrorStr_0F  ; AXERRObjDup        object file already specified (multiple .obj).
        .word ErrorStr_10  ; AXERRList          list file error (open or write).
        .word ErrorStr_11  ; AXERRListDup       list file already specified (multiple .list).
        .word ErrorStr_12  ; AXERRDirectRange   direct assembly address out of range.
        .word ErrorStr_13  ; AXERRBankDirect    .bank requires .direct 
        .word ErrorStr_14  ; AXERRROMBankDirect .rombank requires .direct 
        .word ErrorStr_15  ; AXERRBankInvalid    bank number out of range
        .word ErrorStr_16  ; AXERRBankReq       .bank required for direct assembly to $A000-$BFFF
        .word ErrorStr_17  ; AXERRROMBankReq    .rombank required for direct assembly to $c000-$ffff (52 chars)
        .word ErrorStr_18  ; AXERRMacroIDReq    .macro requires an identifier
        .word ErrorStr_19  ; AXERRMacroIDDup    .macro identifier already exists
        .word ErrorStr_1A  ; AXERRTooManyFiles  Too many nested files
        .word ErrorStr_1B  ; AXERRSourceFile    Source file read error
        .word ErrorStr_1C ; AXERRCondNested     Nested conditional
        .word ErrorStr_1D ; AXERRVirtNested     Nested virtual
        .word ErrorStr_1E ; AXERRCondNoIf       .else/.endif without .if
        .word ErrorStr_1F ; AXERRVirtNoVirt     .endvirtual without .virtual
        .word ErrorStr_20 ; AXERRAssert         Assert failed
        .word ErrorStr_21 ; AXERROrgLogical     Can't change org in a .logical block
        .word ErrorStr_22 ; AXERRReq65C816      Requires 65C816 mode
        .word ErrorStr_23 ; AXERRReq65C02       Requires 65c02 mode
        .word ErrorStr_24 ; AXERRReq16          operand requires 16-bit register mode
        .word ErrorStr_25 ; AXERRBadOperand8    8-bit operand required

; Note: Errors/codes that do not have an error string start at $E0

; This text comes out as upper case in all encodings (PETSCII U, PETSCII UL, ISO)
; The strings that correspond with the APIErrorTable entries.
; When called from EDIT, there is only one line for the error message, so it must all fit
; within 80 characters.
; The format is:
; <error msg> in <fname>:line #
; The file name is truncated if needed, to a max of 36 characters.
; The :xxxx line # number could take 5 chars
; The " in " is 4 chars
; Total: 4+5+36=45. This leaves 80-45=35 chars max for the error message.


ErrorStr_00:    .byte "eof",$00             ; End of File; we should never see this.
ErrorStr_01:    .byte "syntax error",$00
ErrorStr_02:    .byte "bad identifier, missing/too long",$00
ErrorStr_03:    .byte "divide by zero",$00
ErrorStr_04:    .byte "value of an identifier has changed",$00
ErrorStr_05:    .byte "file not found",$00
ErrorStr_06:    .byte "undefined identifier",$00
ErrorStr_07:    .byte "relative branch range",$00
ErrorStr_08:    .byte "address mode not supported",$00
ErrorStr_09:    .byte "bad expression",$00
ErrorStr_0A:    .byte "line too long",$00
ErrorStr_0B:    .byte "too many macro parameters",$00
ErrorStr_0C:    .byte "bad expansion parameter",$00
ErrorStr_0D:    .byte "out of memory",$00
ErrorStr_0E:    .byte "object file error (open or write)",$00
ErrorStr_0F:    .byte "object file already specified",$00
ErrorStr_10:    .byte "list file error (open or write)",$00
ErrorStr_11:    .byte "list file already specified",$00
ErrorStr_12:    .byte "direct assembly address out of range",$00
ErrorStr_13:    .byte ".rambank requires .direct",$00
ErrorStr_14:    .byte ".rombank requires .direct",$00
ErrorStr_15:    .byte "bank number out of range",$00
ErrorStr_16:    .byte ".rambank req for asm to $a000-$bfff",$00  ; 35 chars
ErrorStr_17:    .byte ".rombank req for asm to $c000-$ffff",$00  ; 35 chars
ErrorStr_18:    .byte ".macro requires an identifier",$00
ErrorStr_19:    .byte ".macro identifier already exists",$00
ErrorStr_1A:    .byte "too many nested files",$00
ErrorStr_1B:    .byte "source file read error",$00
ErrorStr_1C:    .byte "nested conditional",$00
ErrorStr_1D:    .byte "nested logical",$00
ErrorStr_1E:    .byte ".else/.endif without .if",$00
ErrorStr_1F:    .byte ".endlogical without .logical",$00
ErrorStr_20:    .byte ".assert failed",$00
ErrorStr_21:    .byte "can't change org in .logical block",$00
ErrorStr_22:    .byte "requires 65c816 mode",$00
ErrorStr_23:    .byte "requires 65c02 mode",$00
ErrorStr_24:    .byte "operand requires 16-bit register mode",$00
ErrorStr_25:    .byte "8-bit operand required",$00

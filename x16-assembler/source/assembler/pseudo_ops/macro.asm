; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       macro.asm
;       Purpose:    .macro command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       May 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   .macro definition
;
; Can be written with the macro identifier either on the left (64TASS compatibility) or the right:
;        name .macro
;        .macro .name
;
; Variable "identifer_count" is set in AssembleLine and tells us if a non-local identifier was found on
; the line containing ".macro". This code first checks for an identifier on the RIGHT and uses that if found.
;
; ************************************************************************************************

AXXMacro:   ;; {.macro}

; We only check for identifiers on pass #1:

        lda AXPass                   ; Which pass are we on?
        cmp #1                       ; Is this pass 1?
        bne  @AXXMacro2              ; Taken if not

; Check for a new identifier on the right side:

        jsr     AXGet                       ; Get first character
        cmp     #0                          ; Anything there?
        beq     @check_right                ; Taken if not
        jsr     AXExtractIdentifier
        bcc     @have_identifier            ; Taken if there is an identifier

; No identifier on the RIGHT, was there one on the left?
@check_right:
        lda     id_count                    ; Was there an identifier: <id> .macro?
        bne    @AXXMacro2                   ; Taken if so... skip check for identifier already exists because... it does!

; Error: .macro requires an identifier
        sec
        lda #AXERRMacroIDReq
        rts

; Identifier found, make sure it is new:

@have_identifier:

        ldy     AXIBase                     ; start scanning.
        ldx     #0
        jsr     AXICreateFind               ; Check if it already exists, create it if not.
        bcs     @AXXMacro2                  ; Taken if it was a new identifier

; AXICreateFind found that the RIGHT side macro indentifier was already present, which is an error:
        sec
        lda #AXERRMacroIDDup
        rts

; The is top of the original macro processing loop. Store the body of the macro with the identifier:
@AXXMacro2:
        jsr     AXReadLine                  ; read the next line
        bcs     @AXMExit                    ; error ?
        jsr     AXMCheckEnd                 ; is this .endm
        bcs     @AXMComplete
        ;
        lda     AXPass                      ; only do the define on pass 1.
        cmp     #2
        beq     @AXXMacro2
        ;
        clc                                 ; append the buffer to the macro.
        jsr     AXIAppendMacro
        bcs     @AXMExit                    ; failed ?
        bra     @AXXMacro2
        ;
@AXMComplete:                               ; do nothing on pass 2.
        lda     AXPass
        cmp     #2
        beq     @AXMExitOkay
        sec                                 ; this appends the NULL to the macro.
        jsr     AXIAppendMacro

@AXMExitOkay:
        clc
@AXMExit:       
        rts

; ************************************************************************************************
;
;                               Check if buffer contains .ENDM
;
; ************************************************************************************************

AXMCheckEnd:
        ldx     #0                          ; first non space.
        jsr     AXGet 
        ldy     #0
@AXMCheck:
        lda     AXBuffer,x                  ; match ?
        cmp     @AXMMarker,y
        clc                                 ; no, return CC
        bne     @AXMExit
        inx                                 ; next chars
        iny
        cmp     #0                          ; two NULLs matched ?
        bne     @AXMCheck                   ; yes, then found .endm
        sec
@AXMExit:
        rts

@AXMMarker:
; Encoding must produce UPPER CASE ASCII
        .byte ".endm",0


        


; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       text.asm
;       Purpose:    .text command (byte with possible tex string)
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble .text command
;
; ************************************************************************************************

AXTextCmd:  ;; {.text}

        ldx     AXOperandPos                ; get operand, must be defined even on pass 1.

@AXTLoop:
        jsr     AXGet                       ; is it a quoted string
        cmp     #'"'
        beq     @AXTText

        jsr     AXPass2Expression           ; get value
        bcs     @AXTExit

        lda     AXPass                      ; only check size on pass 2
        cmp     #2
        bne     @AXTNoCheck

        lda     AXLeft+1
        beq     @AXTNoCheck

        lda     #AXERRSize                  ; not a byte.
        sec
        rts

@AXTNoCheck:
        lda     AXLeft                      ; output the byte.
        jsr     AXWriteByte
        bcs     @AXTExit                    ; A-reg already has error code from AXWriteByte
@AXTNext:
        jsr     AXGet                       ; get next
        inx
        cmp     #','
        beq     @AXTLoop
        cmp     #0
        bne     @AXTSyntax
@AXTOkay:       
        clc
        rts

@AXTText:
        jsr     AXTGetTextString            ; get text string to buffer.
        bcs     @AXTExit                    ; failed
        ldy     #0
@AXTOut:
        lda     AXTextParameter,y           ; get character
        beq     @AXTNext                    ; end of string, do next parameter
        jsr     AXWriteByte
        bcs     @AXTExit                    ; A-reg already has error code from AXWriteByte
        iny                                 ; keep going.
        bra     @AXTOut
@AXTSyntax:
        lda     #AXERRSyntax
        sec
@AXTExit:       
        rts


; ************************************************************************************************
;
;                           Get text string into seperate buffer
;
; ************************************************************************************************

AXTGetTextString:
        jsr     AXGet                       ; get first
        cmp     #'"'                        ; error if not double quotes
        bne     @AXTGError
        ldy     #0
@AXGTSLoop:
        inx                                 ; get the next
        lda     AXBuffer,x
        beq     @AXTGError                  ; EOL
        cmp     #'"'                        ; found end
        beq     @AXTGExit
        sta     AXTextParameter,y           ; write into buffer
        iny
        bra     @AXGTSLoop
@AXTGExit:
        inx                                 ; consume closing "
        lda     #0                          ; make ASCIIZ
        sta     AXTextParameter,y                   
        clc
        rts

@AXTGError:
        sec
        lda     #AXERRSyntax
        rts


        


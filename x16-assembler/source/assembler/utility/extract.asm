; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       extract.asm
;       Purpose:    Extract an identifier.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       July 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                           Extract Identifier at X to LabelBuffer
;
; ************************************************************************************************

AXExtractIdentifier:
        lda     AXBuffer,x                  ; check the first character.
        jsr     AXIsIdentifierHead
        bcs     @AXELFail
        ;
        ldy     #0                          ; save position.
        lda     AXBuffer,x                  ; is the first character a _
        cmp     #ASCII_UNDERSCORE                        ; if so, we need to make it a local
        beq     @local
        cmp     #'@'                        ; Also local if the first char is an @
        bne    @AXELLoop                    ; Taken if NOT
@local:
        pha
        phx                                 ; local header into labelbuffer
        jsr     AXILocalHeader              ; A-reg still contains the first char
        plx
        pla
        ;
@AXELLoop:      
        sta     AXLabelBuffer,y             ; save in buffer, bump position
        iny
        cpy     #AXMaxIdentSize+1           ; too long
        beq     @AXELFail
        inx                                 ; consume character
        lda     #0                          ; make ASCIIZ.
        sta     AXLabelBuffer,y
        ;
        lda     AXBuffer,x                  ; get the next caracter.
        jsr     AXIsIdentifierBody          ; is it a body character
        bcc     @AXELLoop                   ; if so add it to the label.
        ;
        lda     AXLabelBuffer-1,y           ; set bit 7 of last character.
        ora     #$80
        sta     AXLabelBuffer-1,y
        ;
        clc                                 ; successfully acquired a label.
        rts

@AXELFail:
        lda     #AXERRIdentifier            ; bad label.
        sec
        rts

; ************************************************************************************************
;
;                       New local label set, encountered on global label
;
; ************************************************************************************************

AXIBumpLocal:
        sed
        clc
        lda     AXLocalLabelID
        adc     #1
        sta     AXLocalLabelID
        lda     AXLocalLabelID+1
        adc     #0
        sta     AXLocalLabelID+1
        cld     
        rts

; ************************************************************************************************
;
;                                   Make a local label unique
;
; ************************************************************************************************

AXILocalHeader:
; A-reg contains first char, either "_" or "@":
        sta     AXLabelBuffer,y
        iny
        lda     AXLocalLabelID+1
        jsr     @AXILHOut
        lda     AXLocalLabelID
@AXILHOut:
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     @AXILNOut
        pla
@AXILNOut:
        and     #15
        ora     #48
        sta     AXLabelBuffer,y
        iny
        rts     





; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       read.asm
;       Purpose:    Read a line from the source
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Read line from file into buffer
;
; ************************************************************************************************

AXReadLine:
        sed                                 ; increment the BCD line number.
        clc
        lda     AXLineNumberDecimal
        adc     #1
        sta     AXLineNumberDecimal
        lda     AXLineNumberDecimal+1
        adc     #0
        sta     AXLineNumberDecimal+1
        cld

        inc     AXLineNumber                ; bump line number (integer)
        bne     @AXNoCarry
        inc     AXLineNumber+1
@AXNoCarry:

        stz     AXInQuotes                  ; ' " flag reset
        ldx     #0                          ; read from line start
        jsr     AXReadCharacter             ; try to read one.
        bcs     @AXRLEOFExit                ; failed EOF    
        ;
        ;       Read a character successfully
        ;
@AXRLLoop:
        cmp     #13                         ; read EOL ? then exit.
        beq     @AXRLEndLine
        ;
        ;       Have character, decide what to do with it - CR,capitalise, quoted, length check etc.
        ;
        ldy     AXInQuotes                  ; are we in quote mode
        bne     @AXInQuotes
        ;
        cmp     #';'                        ; no, exit if reached comment
        beq     @AXRLConsumeLine
        jsr     AXConvertUpper              ; capitalise it.
        cmp     #'"'                        ; check entering quotes
        beq     @AXEnterQuotes
        cmp     #$27                        ; This is a single quote: '
        bne     @AXOutChar                  ; write otherwise
        ;
        ;       Found ' " entering quotes
        ;
@AXEnterQuotes:     
        sta     AXInQuotes                  ; entering quotes
        bra     @AXOutChar
        ;
        ;       Consume the rest of the line to CR/EOF
        ;
@AXRLConsumeLine:
        jsr     AXReadCharacter
        bcs     @AXRLEndLine
        cmp     #13
        bne     @AXRLConsumeLine
        bra     @AXRLEndLine        
        ;
        ;       In quotes, exit if matching found.
        ;
@AXInQuotes:
        cmp     AXInQuotes                  ; leaving quotes, e.g. matching '" found.
        bne     @AXOutChar                  ; no, just output normally.
        stz     AXInQuotes                  ; reset the in quotes flag.
@AXOutChar:
        sta     AXBuffer,x
        
        inx
        cpx     #AXMaxLineSize-1            ; too long.
        lda     #AXERRLength
        bcs     @AXRLErrExit
        jsr     AXReadCharacter             ; read next
        bcc     @AXRLLoop                   ; loop back if not EOF
        ;
        ;       End of line make ASCIIZ
        ;
@AXRLEndLine:
        stz     AXBuffer,x                  ; make buffer ASCIIZ.
        clc
@AXRLExit: 
        rts     

@AXRLEOFExit:
        stz     AXBuffer                    ; clear buffer
        lda     #AXERREOF                   ; return EOF error, which is complete :)

@AXRLErrExit:       
        sec
        rts


        .segment "VARS"
AXInQuotes:
        .res   1




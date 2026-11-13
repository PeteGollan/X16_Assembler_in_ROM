; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       input.asm
;       Purpose:    Read a character from the input
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                       Read next character, CS on error. Always returns CR for EOL.
;
; ************************************************************************************************

AXReadCharacter:
        phx
        phy
        lda     AXLastCharacter             ; is last character $FF, this means EOF
        cmp     #$FF
        beq     @AXREOF
        ;
@AXNext:        
        ldx     AXFileHandle
        jsr     TAReadChar
        bcs     @AXREOF
        ;
        cmp     #9                          ; convert TAB to space
        bne     @AXRNotSpace
        lda     #' '
@AXRNotSpace:
        cmp     #10                         ; if not LF, exit successfully.
        bne     @AXRExit                    
        ldx     AXLastCharacter             ; check last char was CR
        cpx     #13
        beq     @AXNext                     ; if so its CR/LF so we ignore the LF.
        sta     AXLastCharacter
        lda     #13                         ; return CR, last char still LF.
        bra     @AXRExit2
@AXRExit:
        sta     AXLastCharacter
@AXRExit2:      
        clc
        ply
        plx
        rts

@AXREOF:
        lda     #$FF
        sta     AXLastCharacter
        sec
        ply
        plx
        rts





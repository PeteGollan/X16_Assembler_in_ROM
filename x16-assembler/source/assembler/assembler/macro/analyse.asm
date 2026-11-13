; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       analyse.asm
;       Purpose:    Analyse the instruction parameters
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                       Analyse parameters (X points to end of identifier)
;
;       Creates table in frame of macro parameters - this is a list of positions in AXBuffer.
;                                               CS = Error
;       
; ************************************************************************************************

AXMAnalyseParameters:
        ldy     #0                          ; count the parameters
@AXMAPLoop:
        jsr     AXGet                       ; get the next.
        cmp     #0                          ; if not zero there is a parameter
        bne     @AXMAPParameter
        ;
@AXMAPExit:     
        sty     AXMParamCount               ; save the count of parameters
        txa                                 ; update the last position in the position list.
        sta     AXMParameters,y                 
        clc
        rts
        ;
@AXMAPParameter:
        cpy     #AXMaxParams                ; too many parameters
        beq     @AXMAPError
        ;
        txa                                 ; save the start of the parameter and increment the count
        sta     AXMParameters,y     
        iny
        ;
@AXMAPSkip:     
        jsr     AXGet                       ; get first non-space character
        cmp     #'"'                        ; quoted string handled seperately.
        beq     @AXMAPString        
        cmp     #0                          ; if End found then exit
        beq     @AXMAPExit
        inx                                 ; consume character
        cmp     #','                        ; keep getting if ,
        bne     @AXMAPSkip
        lda     #' '                        ; overwrite with a space so the comma isn't copied out.
        sta     AXBuffer-1,x
        bra     @AXMAPLoop                  ; see if another parameter follows.
        ;
@AXMAPString:
        inx                                 ; get next
        jsr     AXGet       
        cmp     #0                          ; exit if end of string
        beq     @AXMAPExit
        cmp     #'"'                        ; loop back if not closing quote
        bne     @AXMAPString
        inx                                 ; consume closing quote
        bra     @AXMAPSkip                  ; and keep looking.

@AXMAPError:
        lda     #AXERRMacroParams
        sec
        rts


        


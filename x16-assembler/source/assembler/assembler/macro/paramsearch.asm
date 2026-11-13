; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       paramsearch.asm
;       Purpose:    Search the macro line for parameters and call substitute
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;       Scan buffer for parameters. Return A=0 not replaced, A#0 replaced, CS on error
;       
; ************************************************************************************************

AXMScanParameters:
        ldx     #0                          ; look for parameter marker.
@AXMSPLoop:
        lda     AXBuffer,x                  ; look for \
        cmp     #ASCII_BACKSLASH
        beq     @AXMSPFound
        inx
        cmp     #0                          ; reached end.
        bne     @AXMSPLoop

        lda     #0
        clc     
        rts

@AXMSPFound:
        
        lda     AXBuffer+1,x                ; get following character
        sec                                 ; convert to 0-n-1 for parameter 1..n
        sbc     #'1'
        bmi     @AXMSError
        cmp     #AXMaxParams                ; must be 0..maxparams-1
        bcs     @AXMSError
        ;
        pha                                 ; save ID and position.
        phx

@AXMSPRemove:       
        lda     AXBuffer+2,x                ; delete the /n.
        sta     AXBuffer,x
        inx
        cmp     #0
        bne     @AXMSPRemove
        ;
        plx                                 ; restore X (position) A (param#-1)
        pla

        jsr     AXIInsertParameter          ; insert parameter from previous frame.
        bcs     @AXMSExit

        lda     #$FF                        ; and we did a substitution.
        clc
@AXMSExit:      
        rts

@AXMSError:
        lda     #AXERRParam                 ; return parameter error.
        sec
        rts     


        


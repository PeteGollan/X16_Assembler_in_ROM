; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       include.asm
;       Purpose:    .include command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Include a file
;
; ************************************************************************************************

AXInclude:  ;; {.include}

        ldx     AXOperandPos        
        jsr     AXTGetTextString            ; file name to buffeer
        bcs     @AXISyntax                  ; failed.
        ;
        jsr     AXListLine                  ; list line before expansion
        jsr     AXPushFrame                 ; save current frame    

; ca65 didn't like this way of getting the address:
;        ldy     #AXTextParameter >> 8       ; assemble named file
;        ldx     #AXTextParameter & $FF 

        ldy     #>AXTextParameter       ; Note: MSB - assemble named file
        ldx     #<AXTextParameter       ; Note: LSB

        jsr     AXAssembleFile
        php                                 ; restore frame saving the results 
        pha
        jsr     AXPullFrame
        stz     AXBuffer                    ; stop 11th listing.

; AXAsssembleFile opened and closed the include file:
        jsr ListResumingFile                ; Ignore any error here...        

        pla
        plp
        rts

@AXISyntax:
        lda     #AXERRSyntax
        sec     
        rts
        

        


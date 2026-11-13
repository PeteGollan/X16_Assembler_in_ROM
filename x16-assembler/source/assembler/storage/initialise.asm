; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       initialise.asm
;       Purpose:    Initialise the identifier store
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
;                           Initialise the identifier store and stack
;
; Set the stack to end at $xxFF, where xx is ID_STORE_END_PAGE.
; ************************************************************************************************

AXIReset:
        lda #ID_START_PAGE
        ldy #ID_END_PAGE

        sta AXIBase
        sty AXIEnd
        ;
        sty AXIStack+1                      ; reset stack
        lda #$ff
        sta AXIStack                        ; Use the entire last page ($xxFF)
        ;
        lda AXIBase                         ; erase the user definitions.
        sta AXTemp0+1
        stz AXTemp0
        ldx #ID_RAM_BANK                    ; Switch RAM banks to access ID store...
        stx RAM_BANK_REG                
        lda #0
        sta (AXTemp0)
        ldx #HOME_RAM_BANK                  ; ... and switch back
        stx RAM_BANK_REG
        stz AXIMemory                       ; clear out of memory flag.
        rts

        .segment "VARS"
AXIBase:                                    ; MSB of identifier base area
        .res   1       
AXIEnd:                                     ; MSB of identifier end area
        .res   1       
AXIStack:                                   ; Frame stack pointer.
        .res   2       
AXIMemory:                                  ; set when out of memory.
        .res   1       

        


; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       binary.asm
;       Purpose:    .binary command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       July 2026 for the X16-Assembler in ROM project
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Include a binary file
;
; ************************************************************************************************

AXBInclude: ;; {.binary}
AXBInclude2:;; {.incbin}

        ldx AXOperandPos        
        jsr AXTGetTextString    ; file name to buffeer
        bcs @AXISyntax          ; Taken if failed

; ca65 didn't like this way of getting the address:
;        ldy #AXTextParameter >> 8
;        ldx #AXTextParameter & $FF
        ldy #>AXTextParameter   ; Note: MSB
        ldx #<AXTextParameter   ; Note: LSB

        jsr TAOpen              ; Open the file

; We can't use AXFileHandle to store the LFN, because we dont have our own stack frame:
        sta pseudo_op_LFN       ; The LFN/handle has it's own variable
        bcc @AXBOut             ; Taken if open succeeded

; File open failed,A-reg has error code, clean up and exit:

        stz pseudo_op_LFN
        bra @ErrorExit

@AXBOut:
        ldx pseudo_op_LFN       ; The LFN/handle has it's own variable
        jsr TAReadChar
        bcs @AXBEndFile         ; exit on EOF
        jsr AXWriteByte         ; otherwise copy out.
        bcc @AXBOut             ; Taken if write succeeded

; Write failed so close the file and then fall into the common error exit:

        pha
        ldx pseudo_op_LFN       ; We keep our handle/LFN separately
        jsr TAClose             ; close the file.
        pla

; Common error cleanup and exit. A-reg has error code:
@ErrorExit:
        sec
        rts    

@AXBEndFile:
        ldx pseudo_op_LFN       ; We keep our handle/LFN separately
        jsr TAClose             ; Close the binary file.
        clc
@AXBExit:       
        rts

@AXISyntax:
        lda #AXERRSyntax
        sec     
        rts


        


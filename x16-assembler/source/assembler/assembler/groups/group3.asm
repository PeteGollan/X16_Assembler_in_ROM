; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       group3.asm
;       Purpose:    Assemble group 3 instruction (relative branches)
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Assemble group 3 instruction
;
; On entry, GroupTemp contains the line index
; ************************************************************************************************

AXGroup3:
        ldx GroupTemp                      ; Recover the line index
        lda AXBaseOpcode                   ; assemble the base opcode.
        jsr AXWriteByte
        bit write_error_flag               ; Was there a low-level error?
        bmi @AXG3WriteError                ; Taken if so

        lda AXBaseOpcode
        cmp #BaseOpcode_BRL                ; The ONLY 65C816 PC-relative long branch instruction
        beq @do_brl                        ; Taken if so

        jsr AXPass2Expression              ; get expression defined on pass 2.
        bcs @AXG3Exit       

        lda AXPass                         ; pass 1, don't care.
        cmp #1
        beq @AXOutputOffset

        clc                                ; calculate relative branch
        lda AXLeft                         ; we have one too many because of the opcode
        sbc AXProgramCounter               ; so we clc here to borrow one.
        tax
        lda AXLeft+1
        sbc AXProgramCounter+1
        tay

        cpx #0                             ; for 00-7F Y should be 0, for 80-FF it should be $FF
        bpl @AXNotBack                     ; if we bump Y if X is -ve, then if zero it's a fail.
        iny             
@AXNotBack:     
        cpy #0                             ; so check it
        beq @AXOutputOffset
        ;
        sec                                ; if it's not out of range
        lda #AXERRRelative
        bra @AXG3Exit
        ;
@AXOutputOffset:
        txa
        jsr AXWriteByte                    ; output the offset
        bit write_error_flag               ; Was there a low-level error?
        bmi @AXG3WriteError                ; Taken if so
        clc
@AXG3Exit:      
        rts

@AXG3WriteError:
        rts

; This is the BRL 16-bit branch. Similar to 8-bit, but faster to just test and branch once:
@do_brl:

        jsr AXPass2Expression              ; get expression defined on pass 2.
        bcs @AXG3Exit

        lda AXPass                         ; pass 1, don't care.
        cmp #1
        beq @AXOutputOffset2

;  Add 2 to PC to start offset calculation at the next instruction after the BRL:

        clc
        lda AXProgramCounter
        adc #$2
        sta GroupTemp
        lda AXProgramCounter+1
        adc #$0
        sta GroupTemp+1

; Calculate the 16-bit relative branch: <dest addr> - <next instr addr>
; Where GroupTemp has <next instr addr>:

        sec
        lda AXLeft                         ; MSB
        sbc GroupTemp
        sta GroupTemp
        lda AXLeft+1
        sbc GroupTemp+1
        sta GroupTemp +1                   ; MSB

@AXOutputOffset2:
        lda GroupTemp                      ; LSB
        jsr AXWriteByte                    ; output the offset
        bit write_error_flag               ; Was there a low-level error?
        bmi @AXG3WriteError                ; Taken if so
        lda GroupTemp+1                    ; MSB
        jsr AXWriteByte                    ; output the offset
        bit write_error_flag               ; Was there a low-level error?
        bmi @AXG3WriteError                ; Taken if so
        clc                                ; Success exit
        rts


        


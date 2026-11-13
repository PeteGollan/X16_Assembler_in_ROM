; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       rombank.asm
;       Purpose:    .rombank command
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                               Select ROM bank for object code.
;
; ************************************************************************************************

AXROMBankCmd:  ;; {.rombank}


; .bank requires .direct:

@check_direct:
        lda #DIRECT_SET         ; Is .direct set?
        and mem_flags
        bne @bank_ok            ; Taken if so

; Error exit:
        lda #AXERRROMBankDirect
        sec
        rts

@bank_ok:
        ldx AXOperandPos                ; get operand, must be defined even on pass 1.
        jsr AXGet                       ; what follows
        cmp #0
        beq @AXBCIncrement              ; if eol then just increment the bank.

        jsr AXPass2Expression           ; get value
        bcs @AXBSyntaxExit              ; Taken if error in expression

; Check for garbage on line after bank number:
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        beq @check_ok                   ; Taken if so
@AXBSyntaxExit:       
        lda #AXERRSyntax                ; Garbage on line after bank number, so exit:
        sec
        rts

@check_ok:
        lda AXLeft
        sta ROM_bank
        jsr check_rom_bank_num
        bcs @bank_bounds_err
@AXBExit:       
        lda #ROM_BANK_ENABLED 
        ora mem_flags
        sta mem_flags
        clc
        rts

@AXBCIncrement:
        inc ROM_bank          ; next bank

; Is the bank allowed?
        lda ROM_bank          ; Is it a prohibited bank?
        jsr check_rom_bank_num
        bcs @bank_bounds_err     ; C=1, error exit
        
        lda #ROM_BANK_ENABLED
        ora mem_flags
        sta mem_flags
        clc
        rts

; Bounds error exit:
@bank_bounds_err:
        lda #AXERRBankInvalid
        sec
        rts

;---------------------------------------------------------------
; check_rom_bank_num
;
; Inputs : A-reg = bank number 
;
; Returns   C=0 if if bank number is restricted
;             1 otherwise
;
; Allows ROM banks $20-$FF ("cartridge ROM space")
;---------------------------------------------------------------

check_rom_bank_num:

; Check for bank number out of bounds:
        cmp #$20                         ; Allow ROM banks $20-$FF
        bcs @bank_num_ok

@bank_num_err:
        sec
        rts

@bank_num_ok:
        clc
        rts

 
        


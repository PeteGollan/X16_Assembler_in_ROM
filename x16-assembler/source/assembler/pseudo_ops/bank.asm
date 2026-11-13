; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       bank.asm
;       Purpose:    .bank and .rambank commands
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
;                               Select bank for object code.
;
; ************************************************************************************************

AXBankCmd:  ;; {.bank}
AXBankCmd2:  ;; {.rambank}

; .bank requires .direct:

@check_direct:
        lda #DIRECT_SET         ; Is .direct set?
        and mem_flags
        bne @bank_ok            ; Taken if so

; Not direct error:
        lda #AXERRBankDirect
@exit_err:
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
        sta RAM_bank
        jsr check_bank_num
        bcs @bank_bounds_err
@AXBExit:       
        lda #RAM_BANK_ENABLED
        ora mem_flags
        sta mem_flags
        clc
        rts

@AXBCIncrement:
        inc RAM_bank                ; next bank

; Is the bank allowed?
        lda RAM_bank                 ; Is it a prohibited bank?
        jsr check_bank_num
        bcs @bank_bounds_err         ; C=1, error exit
        
        lda #RAM_BANK_ENABLED 
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
; check_bank_num
;
; Inputs : A-reg = bank number 
;
; Returns   C=0 if if bank number is restricted
;             1 otherwise
;---------------------------------------------------------------

check_bank_num:

; Check for bank number out of bounds:
        beq @bank_num_err                ; Don't allow bank 0 (BASIC)
        cmp #RAM_BANK_MIN                ; Lowest .bank
        bcc @bank_num_err                ; Taken if specified bank is < the minimum

; If we have been called from EDIT, bank numbers are further restricted
; to a max of EDIT_BANK_MAX:

        tax
        lda #EDIT_VEC_FLAG      ; Are we in EDIT?
        and vec_flag
        beq @bank_num_ok        ; Taken if not

        txa
        cmp #EDIT_BANK_MAX+1
        bcs @bank_num_err

@bank_num_ok:
        clc
        rts

@bank_num_err:
        sec
        rts


        


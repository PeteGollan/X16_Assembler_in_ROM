; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      apiwrite.asm
;       Purpose :   Write assembled byte 
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       March 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
; TAWriteByte -  Handle byte assembly/save/storage.
;
; On Entry: AXProgramCounter contains addr LSB, addr MSB, and RAM bank in 3 consecutive locations.
;           The byte to write is in Y
; On Exit : Returns C=1 and A-reg=error code if there is an error
;           For low-level write failures, C=1, write_error_flag is set and the error code is in 
;           write_error_code
;
; Uses    : (zp) Temp0, Temp1, WriteByteSave
; ************************************************************************************************

TAWriteByte:

        sty WriteByteSave       ; Safe zero-page location to save the byte to be written

; Increment the tracker while still in common code (A-reg is available):

	sed                     ; Start working in BCD mode 
	clc
	lda BytesWrittenBCD     ; Three BCD bytes to represent 0-999,999. Two would be 0-9999.
	adc #1
	sta BytesWrittenBCD
	lda BytesWrittenBCD+1
	adc #0
	sta BytesWrittenBCD+1
        lda BytesWrittenBCD+2
        adc #0
        sta BytesWrittenBCD+2
        cld                     ; Stop working in BCD mode 

; Set the flag to indicate to .fill that we have written OBJ (file or memory is irrelevant)
; so it can change it's behaviour:

        lda #OBJ_WRITTEN    ; Set the flag
        ora ops_flags
        sta ops_flags

; Writing to memory (.direct)?

        lda #DIRECT_SET
        and mem_flags
        beq @check_obj                  ; Taken if not


        bit logical_flag                   ; Is logical set?
        bpl @use_PC                        ; Taken if not

; .logical set, so use PCDirect for the program counter in .direct mode:

        lda PCDirect                     ; LSB addr
        sta Temp0
        lda PCDirect+1                   ; MSB addr
        sta Temp1
        bra @direct_checks               ; Do the addr checks using the PCDirect addr

@use_PC:
        lda AXProgramCounter            ; LSB addr
        sta Temp0
        lda AXProgramCounter+1          ; MSB addr
        sta Temp1

;---------------------------------------
; Direct assembly address safety checks
;---------------------------------------
; Byte to write is in Y-reg, address MSB is in A-reg:        

@direct_checks:
        bpl @lower                      ; address is <$8000, so only do lower addr checks
        cmp #$9F                        ; $9Fxx is disallowed in both EDIT and BASIC
        beq @direct_addr_err            ; Taken if $9Fxx
        
; Address is upper memory and is NOT $9Fxx:
        cmp #$a0
        bcc @direct_ok                  ; Address is <$A000 but >=$8000, so no further checks

        and #%11100000                  ; We just need the top three bits
        cmp #%10100000                  ; Bank RAM? ($Axxx-$Bxxx)
        beq @check_ram

; It is not bank RAM, so it must be ROM:

; Check for .rombank:
        lda #ROM_BANK_ENABLED              ; Are we also in .rombank mode?
        and mem_flags
        beq @rom_bank_err                  ; Taken if not

; Save the byte in y-reg to the address in the specified ROM bank:

        jsr FarROM_sta                  ; Can't write to another ROM bank from here so...
        bra @check_obj

; Error.. require .rombank for direct assembly into $Cxxx-$Fxxxx
@rom_bank_err:
        lda #AXERRROMBankReq
        sec
        rts
     
@check_ram:
        lda #RAM_BANK_ENABLED              ; Are we also in .bank mode?
        and mem_flags
        beq @ram_bank_err                  ; Taken if not

; Save the byte in y-reg to the address in the specified RAM bank:

        lda RAM_bank            ; bank #
        sta RAM_BANK_REG
        tya                     ; byte to store is in a-reg
        sta (Temp0)
        lda #HOME_RAM_BANK      ; Switch us back home...
        sta RAM_BANK_REG
        bra @check_obj

; Error.. require .bank for direct assembly into $Axxxx-$Bxxxx
@ram_bank_err:
        lda #AXERRBankReq
        sec
        rts

@lower:
        jsr check_lower
        bcc @direct_ok          ; Taken if address is < lower_bound

@direct_addr_err:

        lda #AXERRDirectRange           ; Direct address is out of range
        sta write_error_code
        stz write_error_flag
        dec write_error_flag
        sec
        rts

; Direct assembly for SYS memory.
@direct_ok:

        tya                     ; byte to store is in a-reg
        sta (Temp0)

; Writing to object file?
@check_obj:
        lda     #OBJ_FILE_OPEN          ; Do we have a file?
        and     ops_flags
        beq     @exit_OK                ; Taken if not

;------------------------------------------
; Prepare to write to the file if required
; Byte to be written is in WriteByteSave 
;------------------------------------------

; Do we require a header?

        lda #NOADDR_SET
        and ops_flags       ; Do we require an address?
        bne @write_data     ; Taken if not

        lda #HEADER_WRITTEN
        and ops_flags       ; Have we already written the header?
        bne @write_data     ; Taken if so

; Write the two byte address header and set the flag:

        lda AXProgramCounter       ; Fetch the addr LSB
        ldx obj_LFN
        jsr TAFileWriteByte        ; Write the LSB
        bcs @exit_error

        lda AXProgramCounter+1
        ldx obj_LFN
        jsr TAFileWriteByte       ; Write the LSB
        bcs @exit_error

        lda #HEADER_WRITTEN    ; Set the flag indicating that the header is written
        ora ops_flags
        sta ops_flags

@write_data:
        lda WriteByteSave       ; Fetch the byte to be written
        ldx obj_LFN
        jsr TAFileWriteByte
        bcs @exit_error

@exit_OK:
        clc
        rts

@exit_error:
        rts                     ; Carry flag is already set and a-reg contains error code:

;---------------------------------------------------------------
; check_lower
;
; Returns C=0 if if addr >= bound_lower
;           1 otherwise
;---------------------------------------------------------------

check_lower:
; Compare USBs:
    lda bound_lower+1
    cmp Temp1
    bcc @addr_gt_or_eq      ; Taken if bound_lower < addr
    bne @addr_less          ; Taken if bound_lower >= addr
; Compare LSBs:
    lda bound_lower
    cmp Temp0
    bcc @addr_gt_or_eq    ; Taken if bound_lower < addr
    beq @addr_gt_or_eq    ; Taken if bound_lower <= addr

; Falls into:
@addr_less:
    sec
    rts

@addr_gt_or_eq:
    clc
    rts


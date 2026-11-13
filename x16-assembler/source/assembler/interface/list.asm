; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       list.asm
;       Purpose:    Output listing for current pass
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       May 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Output listing current line.
;
; ************************************************************************************************

AXListLine:

; Only make a listing if a listing file is open AND we are on pass 2:

        lda #LIST_FILE_OPEN     ; Do we have a file?
        and ops_flags
        bne @have_list_file
        rts                     ; Exit if not

@have_list_file:
        lda     AXPass                      ; only on pass 2
        cmp     #2
        beq     @pass_2
        rts

@pass_2:
        lda     AXBuffer                    ; blank line ?
        bne     @list_line                  ; Taken if not
        rts

@list_line:        
        lda     AXLineNumberDecimal+1
        jsr     AXLOutHex
        lda     AXLineNumberDecimal
        jsr     AXLOutHex
        jsr     AXLSpace
        
; List the active bank number as "xx:"

; Show the bank number (RAM or ROM) or blank (SYS memory):
; Determine if we are in sys, ram, or rom:

        bit logical_flag                   ; Is logical set?
        bpl @not_logical0                  ; Taken if NOT
        lda PCDirectStart                  ; Physical address MSB
        bra @cont0

@not_logical0:
        lda     AXProgramCounterStart+1     ; Address MSB
@cont0:
        cmp     #$A0                        ; In Banking memory?
        bcc     @list_sys                   ; address is <$A000, so it is sys
; We are in a bank (RAM or ROM), which one?

        cmp     #$C0                        ; ROM bank?
        bcc     @list_ram_bank              ; Taken if not
        lda     ROM_bank
        bra     @list_bank_num

@list_ram_bank:
        lda     RAM_bank
@list_bank_num:
        jsr     AXLOutHex
        bra @list_PC

; Sys memory, so list two blank spaces instead of a bank number:
@list_sys:
        jsr     AXLSpace 
        jsr     AXLSpace
   
@list_PC:
        lda     #58                         ; ':'
        jsr     AXListOut

        bit logical_flag                   ; Is logical set?
        bpl @not_logical1                  ; Taken if NOT

; Logical lists physical (direct) address first:
        lda     PCDirectStart+1     ; Address
        jsr     AXLOutHex
        lda     PCDirectStart+0     
        jsr     AXLOutHex
        jsr     AXLSpace

@not_logical1:
        lda     AXProgramCounterStart+1     ; Address
        jsr     AXLOutHex
        lda     AXProgramCounterStart+0     
        jsr     AXLOutHex

; Logical adds a "^" after the logical address instead of a space:
        bit logical_flag                   ; Is logical set?
        bpl @not_logical2                  ; Taken if NOT
        lda #'^'                       ; List "^" for logical after addr
        jsr AXListOut
        bra @cont1

@not_logical2:

;*** This space was not needed
;***        jsr     AXLSpace

@cont1:
        ldx     #0                          ; output listing bytes
@AXLHex:
        jsr     AXLSpace                    ; space
        cpx     AXListCount                 ; compare against done.
        bcs     @AXLSpace                   ; if <= done then output spaces.
        lda     AXListBytes,x   
        jsr     AXLOutHex                   ; output hex 
        bra     @AXLLLoop
@AXLSpace:
        jsr     AXLSpace
        jsr     AXLSpace
@AXLLLoop:      
        inx
        cpx     #AXListByteCount            ; done all of them
        bne     @AXLHex
        ;
        jsr     AXLSpace                    ; another space.
        ldx     #0                          ; output the line.
@AXOutLine:
        lda     AXBuffer,x
        beq     @AXEnd
        jsr     AXConvertUpper
        jsr     AXListOut
        inx
        bra     @AXOutLine
@AXEnd:     
        lda     #13                         ; CR/LF
        jsr     AXListOut
        rts

; ************************************************************************************************
;
;               Store first listing bytes for display (first 4 at present)
;
; ************************************************************************************************

AXAddListingByte:
        ldx     AXListCount                 ; already max listable
        cpx     #AXListByteCount
        beq     @AXAExit
        sta     AXListBytes,x               ; store the byte
        inc     AXListCount                 ; bump count

@AXAExit:       
        rts

; ************************************************************************************************
;
;                                           Output A in Hex
;
; ************************************************************************************************

AXLOutHex:                              
        pha                                 ; do upper nibble
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     @AXLOutNibble
        pla                                 ; do lower nibble
@AXLOutNibble:  
        and     #15
        cmp     #10
        bcc     @AXLNotHex
        adc     #6
@AXLNotHex:
        adc     #48
        jmp     AXListOut               

; ************************************************************************************************
;
;                                       Call the API function
;
; ************************************************************************************************

AXLSpace:
        lda     #32
AXListOut:
        jsr TAListChar          ; A-reg has char to list, X and Y preserved
        rts






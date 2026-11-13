; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       opcode.asm
;       Purpose:    Assemble an opcode
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Assemble an opcode
;
; ************************************************************************************************

AXPAssembleOpcode:
        ldy #AXID_Flags                 ; Get the flags
        jsr AXIGet
        sta AXFlags                     ; Save them
        bit sd_flags                    ; Is 65C02 mode set?
        bvc @dispatch65c02              ; Taken if so...

; 65C816 mode is set, but is the instruction 65C816 compatible?
        and #SD_65C816                  ; Is the instruction compatible with 65C816?
        bne @dispatch                   ; Taken if so

        lda #AXERRReq65C02              ; Error: instruction is not compatible with 65C816:
        sec
        rts

; 65C02 mode is set, but is the instruction 65C02 compatible?
@dispatch65c02:
        and #SD_65C02                   ; Is the instruction compatible with 65C02?
        beq @errC02                     ; Taken if NOT

@dispatch:
        ldy #AXID_DataHigh                 ; get the base opcode.
        jsr AXIGet
        sta AXBaseOpcode
        ;
        ldy #AXID_DataAux                  ; get the aux data (selectors for Group 2)
        jsr AXIGet
        sta AXSelector
        ;
        ldy #AXID_DataLow                  ; get the group number
        jsr AXIGet
        sta AXGroup
        stx GroupTemp                      ; Save the line parsing index
        dec a                              ; 0-3
;***        and #$03                ; Ensure the group number is 0-3
        asl a                              ; x2 to form dispatch table index
        tax
        jmp (@DispatchTable,x)

@DispatchTable:
        .word AXGroup1
        .word AXGroup2
        .word AXGroup3
        .word AXGroup4

@errC02:
        lda #AXERRReq65C816
        sec
        rts


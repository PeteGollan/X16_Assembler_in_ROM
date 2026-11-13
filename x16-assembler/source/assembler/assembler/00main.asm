; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       00main.asm
;       Purpose:    Entry point.
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       July 2026 for the X16-Assembler in ROM project
;       * Added code to AXAssemblerPass to call AssembleFile with AsmFileName instead of NULL
;         so that the source filename is recorded in FNameSaveTable in AXAssembleFile.
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Assemble code
;
; ************************************************************************************************

AXAssemble:
        jsr AXIReset            ; reset the identifier system.
        lda #1
        jsr AXAssemblerPass
        bcs @AXAExit
        lda #2
        jsr AXAssemblerPass
@AXAExit:
        rts
        
; ************************************************************************************************
;
;                                           Do Pass A
;
; ************************************************************************************************

AXAssemblerPass:

        sta AXPass              ; set the pass

        jsr ListPass            ; List the pass

        stz AXProgramCounter    ; zero the program counter + bank
        stz AXProgramCounter+1
        stz RAM_bank
        stz ROM_bank

; Defaults for every pass:
        lda #SD_65C02           ; Default to 65C02 processor
        sta sd_flags
        stz rs_flags            ; Default to 8-bit register sizes

        ldx #<AsmFileName       ; assemble the default file.
        ldy #>AsmFileName

        jsr AXAssembleFile
        rts






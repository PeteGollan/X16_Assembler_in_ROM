; ************************************************************************************************
; ************************************************************************************************
;
;       Name :      apifarcall.asm
;       Purpose :   Far Call handler code
;       Date :      11th March 2025
;       Author :    Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;                             Call the appropriate farjsr routine
;                     The parameter is the 4 digit hex address e.g. FFD2
;
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                Copy the table to the RAM duplicate
;
; Note: assumes TA_FarCall_Table is <= 256 bytes.
; ************************************************************************************************

TA_CopyCallToRAM:
        ldx     #0
@TALoop:
        lda     FarCall_Table,x
        sta     FarCall_RAM_Table,x
        inx
        cpx     #FarCall_Table_End-FarCall_Table
        bne     @TALoop        
        rts

; ************************************************************************************************
;
;       Table of JSRFAR call : TA_Call_XXXX where XXXX is the routine address.
;
; ************************************************************************************************

FarCall_Table:
        .include "farcalls.asm"
FarCall_Table_End:

        .segment "VARS"

FarCall_RAM_Table:
        .res   FarCall_Table_End - FarCall_Table        

; These definitions map the addresses of the trampoline functions in our ROM to
; where they will be in our RAM bank. This is here because I couldn't figure out
; how to make a "logical" block in ca65.
; The := make them a label so they will show in the symbol table:


FarSETNAM := ROM_FarSETNAM-FarCall_Table+FarCall_RAM_Table
FarSETLFS := ROM_FarSETLFS-FarCall_Table+FarCall_RAM_Table
FarOPEN   := ROM_FarOPEN-FarCall_Table+FarCall_RAM_Table
FarREADST := ROM_FarREADST-FarCall_Table+FarCall_RAM_Table
FarCLOSE  := ROM_FarCLOSE-FarCall_Table+FarCall_RAM_Table
FarCLRCHN := ROM_FarCLRCHN-FarCall_Table+FarCall_RAM_Table
FarCHKIN  := ROM_FarCHKIN-FarCall_Table+FarCall_RAM_Table
FarCHKOUT := ROM_FarCHKOUT-FarCall_Table+FarCall_RAM_Table
FarCHROUT := ROM_FarCHROUT-FarCall_Table+FarCall_RAM_Table
FarGETIN  := ROM_FarGETIN-FarCall_Table+FarCall_RAM_Table
Far2MCIOUT:= ROM_Far2MCIOUT-FarCall_Table+FarCall_RAM_Table
Far2MACPTR:= ROM_Far2MACPTR-FarCall_Table+FarCall_RAM_Table
FarROM_sta:= ROM_FarROM_sta-FarCall_Table+FarCall_RAM_Table
FarSETTIM := ROM_FarSETTIM-FarCall_Table+FarCall_RAM_Table
FarRDTIM  := ROM_FarRDTIM-FarCall_Table+FarCall_RAM_Table

        .segment "CODE"

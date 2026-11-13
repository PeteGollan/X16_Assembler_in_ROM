; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       list.asm
;       Purpose:    .list command
;       Created:    26 March 2026
;       Original Author: Paul Robson (paul@robsons.org.uk)
;       Copied from "include.asm" and modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                            Set an list file name and open the list file
;
; ************************************************************************************************

AXList:  ;; {.list}

; This solved a build problem early on and now we are stuck with it. The code is here:
; "source\api\x16\apifile.asm"

        jmp     ListOpen





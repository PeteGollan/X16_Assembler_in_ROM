; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       object.asm
;       Purpose:    .obj and .object commands
;       Created:    21 March 2026
;       Original Author: Paul Robson (paul@robsons.org.uk)
;       Copied from "include.asm" and modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                            Set an object file name and open the object file
;
; ************************************************************************************************

AXObj:     ;; {.obj}
AXObject:  ;; {.object}

; This solved a build problem early on and now we are stuck with it. The code is here:
; "source\api\x16\apifile.asm"

        jmp     ObjOpen





; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       macro.asm
;       Purpose:    Assemble a macro
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
;                                   Assemble a macro, parameters from X.
;
; ************************************************************************************************

AXPAssembleMacro:
        jsr     AXMAnalyseParameters        ; work out the parameters limits.
        bcs     @AXPAMExit                  ; error (probably too many parameters)
        jsr     AXIBumpLocal                ; we need new locals.

        jsr     AXIGetDataAddress           ; get address of macro data => YX

        phx
        phy
        jsr     AXPushFrame                 ; save current frame preserving YX
        ply
        plx

        stx     AXMPointer                  ; save macro expansion pointer in current frame.
        sty     AXMPointer+1

@AXPALoop:
        jsr     AXIGetDataLine              ; get data line
        bcs     @AXPADone                   ; end of lines.
        
@AXPAParam:
        jsr     AXMScanParameters           ; look for parameters
        bcs     @AXPAMacroFailed            ; error in expansion ?
        cmp     #0                          ; if one replaced retry.
        bne     @AXPAParam

        jsr     AXAssembleLine              ; assemble that line
        bcs     @AXPAMacroFailed            ; something went wrong.
        jsr     AXListLine                  ; list the line.
        bra     @AXPALoop

@AXPADone:      
        jsr     AXPullFrame                 ; pull previous frame
        clc                                 ; return okay
@AXPAMExit:
        rts

@AXPAMacroFailed:
        pha                                 ; save error code
        jsr     AXPullFrame                 ; restore frame
        pla                                 ; get error code back and return error.
        sec
        rts     


        


; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       logical.asm
;       Purpose:    .logical/.endlogical pseudo ops
;       Created by: Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       September 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

;------------------------------
; .logical pseudo-op handler
;------------------------------
AXLogical:  ;; {.logical}

        bit logical_flag        ; Already set?
        bmi @AXLogNested       ; Taken if so

; Operand is optional:
        ldx AXOperandPos                ; get operand, must be defined even on pass 1.
        jsr AXGet                       ; what follows?
        cmp #0
        beq @AXSyntax                   ; if eol then SYNTAX ERROR *** for now ***

        jsr AXPass2Expression           ; Get new origin
        bcs @AXSyntax                   ; Taken if error in expression

; Check for garbage on line after origin
        jsr AXGet                       ; What follows?
        cmp #0                          ; Is it nothing?
        bne @AXSyntax                   ; Taken if NOT
 
@check_ok:
        stz logical_flag
        dec logical_flag                ; SET the logical_flag

; Set PCDirect and PCDirectStart to the current program counter:

        lda AXProgramCounter            ; Both counters are the same until the origin is changed in the logical block
        sta PCDirect
        sta PCDirectStart
        lda AXProgramCounter+1
        sta PCDirect+1
        sta PCDirectStart+1

; Calculate PCDirectDelta (new PC - AXProgramCounter)
        sec
        lda AXLeft                         ; New PC
        sbc AXProgramCounter               ; Current PC
        sta PCDirectDelta
        lda AXLeft+1
        sbc AXProgramCounter+1
        sta PCDirectDelta+1

; Set the new, logical program counter and logical program counter start:

        lda AXLeft                      ; New origin LSB
        sta AXProgramCounter
        sta AXProgramCounterStart
        lda AXLeft+1
        sta AXProgramCounter+1
        sta AXProgramCounterStart+1

        clc
        rts

@AXLogNested:
        lda #AXERRLogNested
        bra @AXIExit_err

@AXSyntax:
        lda #AXERRSyntax
@AXIExit_err:
        sec
        rts

;---------------------------------
; .endlogical pseudo-op handler
;---------------------------------

AXEndLogical:  ;; {.endlogical}

        bit logical_flag        ; It must already be set.
        bpl @AXLogNotSet

; Ensure there is no operand:
        ldx AXOperandPos
        jsr AXGet                       ; What follows (should be nothing)?
        cmp #0
        bne @AXSyntax                  ; Taken if there is something (garbage on line)

        stz logical_flag                ; CLEAR the logical_flag

; At this point, logical is OFF, but the pseudo-op line has not be listed. Supporting variables
; must be set up for line to be listed correctly. Restore AXProgramCounter and AXProgramCounterStart
; from PCDirect:

        lda PCDirect
        sta AXProgramCounter
        sta AXProgramCounterStart       ; They are the same for pseudo-op that produces no object code
        lda PCDirect+1
        sta AXProgramCounter+1
        sta AXProgramCounterStart+1

        clc
        rts


@AXLogNotSet:
        lda #AXERRLogNoLog
        bra @AXExit_err

@AXSyntax:
        lda #AXERRSyntax
@AXExit_err:
        sec
        rts






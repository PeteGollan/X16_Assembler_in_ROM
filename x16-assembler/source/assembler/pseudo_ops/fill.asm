; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       fill.asm
;       Purpose:    .fill command
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
;        Assemble fill/res command:
;        .fill <n>[,<fillvalue>] allocates <n> bytes but only outputs fill bytes
;        if we are already writing to an object file. This enables the use of .fill to
;        define zeropage variables.
;
;                       (have a look in data.inc source file for some examples)
; ************************************************************************************************

AXFillCmd:  ;; {.fill}
AXResCmd:   ;; {.res}
AXFillCmd2: ;; {.ds}

        stz     FillValue                       ; Default fill value is $00
        ldx     AXOperandPos                    ; get operand, must be defined even on pass 1.
        jsr     AXExpressionDefined
        bcc @exp_ok
        rts                                     ; Error exit, A-reg has error, C is set

@exp_ok:
        lda     AXLeft          ; Save the fill length:
        sta     FillLength
        lda     AXLeft+1
        sta     FillLength+1

; Look for optional fill value:

        jsr     AXGet                       ; get next
        inx
        cmp     #','
        beq     @AXFFillValue
        cmp     #0
        beq     @DoFill

; Something unexpected at the end of the line:
@AXFSyntax:
        lda     #AXERRSyntax
        sec  
        rts

; An optional fill value has been detected:
@AXFFillValue:

        jsr     AXPass2Expression           ; get value
        bcs     @AXFExit

        lda     AXPass                      ; only check size on pass 2
        cmp     #2
        bne     @AXFNoCheck

        lda     AXLeft+1
        beq     @AXFNoCheck

        lda     #AXERRSize                  ; not a byte.
        sec
        rts

@AXFNoCheck:
       lda     AXLeft                      ; Get the byte.
       sta     FillValue                   ; Set the fill value.

@DoFill:
        lda #OBJ_WRITTEN
        and ops_flags     ; True?
        bne @ObjFill      ; Taken if so (fill by writing to the object file)

; We are not writing to an object file, so adjust program counter without
; producing output:

        clc
        lda     AXProgramCounter
        adc     FillLength
        sta     AXProgramCounter
        lda     AXProgramCounter+1
        adc     FillLength+1
        sta     AXProgramCounter+1

; If .logical, also update PCDirect address:

        bit logical_flag                   ; Is logical set?
        bpl @cont                          ; Taken if not

        clc
        lda     PCDirect
        adc     FillLength
        sta     PCDirect
        lda     PCDirect+1
        adc     FillLength+1
        sta     PCDirect+1

        bra     @cont

; If AXWriteByte is writing to a sequential object file, we can't skip ahead with
; the program counter. Instead, we send n fill bytes, where n = 16-bit AXLeft. This routine
; correctly handles the case where AXLeft is zero (by doing nothing).

@ObjFill:
@next:
        sec
        lda FillLength
        sbc #1
        sta FillLength
        lda FillLength+1
        sbc #0
        sta FillLength+1
        bcc @cont
        lda FillValue           ; A-reg = fill byte
        jsr AXWriteByte         ; Preserves all regs
        bcc @next
; Carry set, write returned error in write_error_code:
        rts

@cont:
        clc
@AXFExit:
        rts


        


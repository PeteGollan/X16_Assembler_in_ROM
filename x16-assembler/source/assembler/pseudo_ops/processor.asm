; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       processor.asm
;       Purpose:    processor selection commands: .p65C02 and .p65C816
;       Created:    September 2026
;       Author:     Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;
; ************************************************************************************************
; ************************************************************************************************

        .segment "CODE"

; ************************************************************************************************
;
; .p65C02 and .p65C816 set flags to tell the assembler which instruction sets
; and pseudo ops to use. This method allows for additional processors to be added.
;
; ************************************************************************************************

AXP65C02:  ;; {.p65c02}

        lda #(SD_65C816^$FF) ; Inverse bitmap
        and sd_flags    ; Clear the 65C816 flag
        sta sd_flags

        lda #SD_65C02
        ora sd_flags    ; Set the 65C02 flag
        sta sd_flags

        clc
        rts

AXP65C816:  ;; {.p65c816}

        lda #(SD_65C02^$FF) ; Inverse bitmap
        and sd_flags    ; Clear the 65C02 flag
        sta sd_flags

        lda #SD_65C816
        ora sd_flags    ; Set the 65C816 flag
        sta sd_flags

        clc
        rts


; ************************************************************************************************
;
; .a8 .a16 .i8 i16
;
; These tell the assembler to use 8/16-bit for accumulator (.a8/.a16) or index (.i8/.i16)
; for immediate mode data. These flags are initialized to .a8/.i8. on startup. They retain
; their settings across processor changes.
; ************************************************************************************************

AXm8:  ;; {.a8}

        bit sd_flags    ; 65C816 mode set?
        bvs @ok         ; Taken if so

; Error
        lda #AXERRReq65C816
        sec
        rts

@ok:
        lda #(RS_a16^$FF) ; Inverse bitmap to clear
        and rs_flags      ; Clear the flag
        sta rs_flags
        clc
        rts


AXm16:  ;; {.a16}

        bit sd_flags    ; 65C816 mode set?
        bvs @ok         ; Taken if so

; Error
        lda #AXERRReq65C816
        sec
        rts

@ok:

        lda #(RS_a16)     ; Bitmap to set
        ora rs_flags      ; Setr the flag
        sta rs_flags
        clc
        rts

AXx8:  ;; {.i8}

        bit sd_flags    ; 65C816 mode set?
        bvs @ok         ; Taken if so

; Error
        lda #AXERRReq65C816
        sec
        rts

@ok:
        lda #(RS_i16^$FF) ; Inverse bitmap to clear
        and rs_flags      ; Clear the flag
        sta rs_flags
        clc
        rts


AXx16:  ;; {.i16}

        bit sd_flags    ; 65C816 mode set?
        bvs @ok         ; Taken if so

; Error
        lda #AXERRReq65C816
        sec
        rts

@ok:
        lda #(RS_i16)     ; Bitmap to set
        ora rs_flags      ; Setr the flag
        sta rs_flags
        clc
        rts




; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       modes.inc
;       Purpose:    Address modes
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************


; ************************************************************************************************
;
;                                       Address modes.
;
;   Bits 0..5 represent 4 steps in bytes from 00.07 for Group2 . Group 1 is slightly different.
;   Bit 7 set if zero page address required.
;
; ************************************************************************************************

AXMRequireZero = $80

AXMImmediate =          $00 + AXMRequireZero    ; lda #$2A
AXMZero =               $01 + AXMRequireZero    ; lda $2A
AXMAccumulator =        $02                     ; inc OR inc A
AXMAbsolute =           $03                     ; lda $2ABC
AXMIndirectY =          $04 + AXMRequireZero    ; lda ($2A),y
AXMZeroX =              $05 + AXMRequireZero    ; lda $2A,x
AXMAbsoluteY =          $06                     ; lda $2ABC,y
AXMAbsoluteX =          $07                     ; lda $2ABC,x
AXMIndirect =           $08 + AXMRequireZero    ; lda ($2A)
AXMZeroY =              $09 + AXMRequireZero    ; ldx $2A,y
AXMAbsoluteIndirect =   $0A                     ; jmp ($2ABC)
AXMAbsoluteIndirectX =  $0B                     ; jmp ($2ABC,x)
AXMRelative =           $0C                     ; bra $2A (not used)
AXMIndirectX =          $0D + AXMRequireZero    ; lda ($2A,x)
AXMImmediate2 =         $0E                     ; lda #$1234 - 65C816 if .a16 (group 1) or .i16 (group 2) is set
AXMZeroS =              $0F + AXMRequireZero    ; lda $12,s - 65C816
AXMSRII =               $10 + AXMRequireZero    ; lda ($12,s),y - 65C816
AXMAbsLong =            $11                     ; lda $123456 - 65C816
AXMAbsLongX =           $12                     ; lda $123456,x - 65C816
AXMIndirectLong =       $13 + AXMRequireZero    ; lda [$2A] - 65C816
AXMIndirectLongY =      $14 + AXMRequireZero    ; lda [$2A],y - 65C816
AXMxyc =                $15                     ; mvp #$12,#$32

; NOTE: UPDATE Gr1AddrMode Table to reflect changes here.


        

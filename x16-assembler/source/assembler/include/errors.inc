; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       errors.inc
;       Purpose:    Error codes
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;       Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       March 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************


; ************************************************************************************************
;
;                                       Error codes
;
;                     lower 6 bits are ID, bit 7 identifies a fatal error.
;
; NOTE: When adding new error codes or rearranging error codes, make corresponding changes to:
;       \Source\Repos\cx16\x16-assembler\source\api\x16\apierror.asm
;
; ************************************************************************************************


AXERREOF         = $00    ; end of file, not assembler error.
AXERRSyntax      = $01    ; general syntax error.
AXERRIdentifier  = $02    ; bad identifier, missing/too long.
AXERRDivZero     = $03    ; divide by zero.
AXERRRedefine    = $04    ; value of an identifier has changed.
AXERRNotFound    = $05    ; source file not found.
AXERRUndefined   = $06    ; undefined identifier.
AXERRRelative    = $07    ; relative branch range.
AXERRMode        = $08    ; address mode not supported
AXERRSize        = $09    ; bad expression.
AXERRLength      = $0A    ; line too long.
AXERRMacroParams = $0B    ; too many macro parameters.
AXERRParam       = $0C    ; bad expansion parameter.
AXERRMemory      = $0D    ; out of memory.
AXERRObject      = $0E    ; Object file error (open or write).
AXERRObjDup      = $0F    ; Object file already specified (multiple .obj)
AXERRList        = $10    ; List file error (open or write).
AXERRListDup     = $11    ; List file already specified (multiple .list)
AXERRDirectRange = $12    ; Direct assembly address out of range.
AXERRBankDirect  = $13    ; .bank requires .direct 
AXERRROMBankDirect = $14  ; .rombank requires .direct 
AXERRBankInvalid = $15    ; bank number out of range (for RAM or ROM banks)
AXERRBankReq     = $16    ; .rambank required for direct assembly to $A000-$BFFF (49 chars)
AXERRROMBankReq  = $17    ; .rombank required for direct assembly to $C000-$FFFF (52 chars)
AXERRMacroIDReq  = $18    ; .macro requires an identifier
AXERRMacroIDDup  = $19    ; .macro identifier already exists
AXERRTooManyFiles= $1A    ; Too many nested files
AXERRSourceFile  = $1B    ; Source file read error
AXERRCondNested  = $1C    ; Nested conditional
AXERRLogNested   = $1D    ; Nested logical
AXERRCondNoIf    = $1E    ; .else/.endif without .if
AXERRLogNoLog    = $1F    ; .endlogical without .logical
AXERRAssert      = $20    ; Assert failed
AXERROrgLogical  = $21    ; Can't change org in a .logical block
AXERRReq65C816   = $22    ; Requires 65c816 mode (can be instruction or pseudo op)
AXERRReq65C02    = $23    ; Requires 65c02 mode (can be instruction or pseudo op)
AXERRReq16       = $24    ; operand requires 16-bit register mode
AXERRBadOperand8 = $25    ; 8-bit operand required

; Next is $26

; Additional errors/codes with NO corresponding error string:
AXERRSUCCESS     = $00  ; Assembly success (not really an error)
AXERRNOFILE      = $E1  ; Source file not specified (e.g. ASM "")


; SEE NOTE ABOVE about adding new error codes.





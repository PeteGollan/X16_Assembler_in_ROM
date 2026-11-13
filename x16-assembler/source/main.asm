; ************************************************************************************************
;
;       Name   :   main.asm
;       Purpose:   System interface for the X16-Assembler in ROM Project
;       Author :   Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       Date   :   November 2026
;
; ************************************************************************************************

; Comment out one of these:
DEBUG=0         ; no debug
;DEBUG=1         ; debug

; ************************************************************************************************
;
;                 Interface between the X16 system and X16-Assembler
;
; EDIT_vec  - Called from X16-EDIT Toolbox
; BASIC_vec - Called from BASIC command prompt
; SURPRISE1_vec - (future)
; SURPRISE2_vec - (future)
;
; ************************************************************************************************

.define ASM_VERS "0.07"

;---------------------------------------------------------
; CONSTANTS
;---------------------------------------------------------
KERNAL_buffer   = $BF00         ; In RAM bank zero
BASIC_DELTA_RETURN = $BFF8      ; Put the asm time (3 bytes) $BFF8, F9, FA
BASIC_BO_RETURN = $BFFB         ; Where we put bytes out (3 bytes) $BFFB, FC, FD
BASIC_EC_RETURN = $BFFE         ; Where we put the error code (2 bytes) $BFFE, FF
MAGIC_BYTE_1    = $FA           ; If MAGIC_BYTE_1 and _2 are at BASIC_EC_RETURN...
MAGIC_BYTE_2    = $FB           ; ... on ENTRY from BASIC, we surpress output.

KERNAL_ROM_BANK = $00
KERNAL_RAM_BANK = $00
;The bank this code is running in.
;HOME_ROM_BANK   = $20   ; Use $20/32 for ROAM cartridge development.
HOME_ROM_BANK   = $10  ; Use $10/16 for KERNAL ROM integration.
HOME_RAM_BANK   = $01   ; RAM bank for our variables (can be any bank except 0)
ID_RAM_BANK     = $02   ; Identifier store

; The identifier/symbol table resides in RAM bank 2. It could use the entire bank:
ID_START_PAGE = $A7 ; This is 6400 bytes of identifier/symbol table for now
ID_END_PAGE   = $BF ; The very end of our RAM bank

; ZP Bank Registers:
RAM_BANK_REG = $00
ROM_BANK_REG = $01

; ZP KERNEL Registers (each register is 2 bytes)
KERNAL_R0 = $02
KERNAL_R1 = $04
KERNAL_R2 = $06
KERNAL_R3 = $08

;----------------------------------------------------------
; Character Encoding Constants
;----------------------------------------------------------

CR = $0D	; AKA \r - THIS IS THE NEW LINE CHARACTER IN COMMODORE
CLS = $8F       ; Clear screen

; ASCII character constants because assemblers do dodgy things with character encoding:
ASCII_1 = $31
ASCII_A = $41
ASCII_S = $53
ASCII_X = $58
ASCII_Y = $59
ASCII_Z = $5A

ASCII_a = $61
ASCII_z = $7A

ASCII_BACKSLASH  = $5C
ASCII_UNDERSCORE = $5F

;----------------------------------------------------------
; Parameter Constants
;----------------------------------------------------------
; These values determine bounds and are inclusive (LOW-HIGH)
; These are specific for a given entry vector (e.g. EDIT_vec)
DIRECT_LOWER_EDIT = $0801     ; Low bound (inclusive)
DIRECT_UPPER_EDIT = $9EFF     ; High bound (inclusive)

DIRECT_LOWER_BASIC = $0400      ; Low bound (inclusive)
DIRECT_UPPER_BASIC = $9EFF      ; High bound (inclusive)
EDIT_BANK_MAX      = 9          ; Highest bank number we can use when called from EDIT
RAM_BANK_MIN       = 3          ; This is the lowest RAM bank we can use for .bank (1 and 2 are used)
OPEN_FILES_MAX     = 8          ; Set to total file channels available (KERNAL PR #458)
MAX_ERR_FNAME_LEN = 32          ; We save up to 32 characters of the filename + NULL
FNAME_SAVE_SIZE   = MAX_ERR_FNAME_LEN+2   ; Reserves space for the MAX_ERR_FNAME_LEN plus "*" plus NULL

;----------------------------------------------------------
; Constants to apease the assembler
;----------------------------------------------------------
; ca65 was having a problem doing this calculation in the instruction:
FSTAPtr = FNameSaveTable-FNAME_SAVE_SIZE

;---------------------------------------------------------
; Zero Page - $22-07F are available
;---------------------------------------------------------
        .zeropage

ZPSTARTADDR = *     ; Start of ZP
AuxOut:            .res 4      ; Used by the debugger so don't use it.
MemPtr:            .res 2
Temp0:             .res 1 ; Only valid within a single functon
Temp1:             .res 1
Temp2:             .res 1
GroupTemp:         .res 2 ; Used by instruction group handlers (Opcode, Group1, Group2, Group3, Group4)
AXTemp0:           .res 3 ; 3 bytes as it is used for the API output function (*** IS THIS STILL TRUE? ***)

logical_flag:      .res 1 ; Logical mode set
WriteByteSave:     .res 1 ; Used by TAWriteByte to save the byte to be written
FileWriteByteSave: .res 1 ; Used by TAFileWriteByte to save the byte to be written
RAM_bank:          .res 1 ; Currently selected RAM bank $02-$09 (EDIT) or $02-$FF (BASIC) for direct assembly
ROM_bank:          .res 1 ; Currently selected ROM bank ($20-$FF) for direct assembly
nFilesOpen:        .res 1 ; Used to prevent opening more files than are available (OPEN_FILES_MAX)
pseudo_op_LFN:     .res 1 ; Can be used by any pseudo op that doesn't use a stack frame (e.g. .binary/.incbin)
obj_LFN:           .res 1 ; Assigned LFN for .obj file
list_LFN:          .res 1 ; Assigned LFN for .list file
BytesWrittenBCD:   .res 3 ; Total number of bytes written out (0-999,999), BCD numberm LSB FIRST
bcd0:              .res 3 ; Decimal number to be converted by BCD3_Str_NLZ, LSB FIRST
TempFNameSavePtr:  .res 2 ; Safe place to save the filename pointer during the OPEN sequence
CurFNameSavePtr:   .res 2 ; Points at the filename of the currently open file in FNameSaveTable

; These are set by the entry vector (e.g. EDIT_vec, BASIC_vec)
; In zp because they are heavily accessed during direct assembly.
bound_lower:       .res 2    ; Direct mode address upper bound
bound_upper:       .res 2    ; Direct mode address lower bound

; These add a low-level write failure (several options) error reporting mechanism.
; Write failures include file write error and direct assembly out of range
write_error_flag:  .res 1   ; AXWriteByte error (and possibly others)
write_error_code:  .res 1   ; AXWriteByte error (and possibly others)

id_count:          .res 1   ; Incremented if an identifier was found on the current line (used by .macro).
id_valid_flag:     .res 1   ; Set if a label meets the requirements to be valid

TAHandleTracker:   .res 1   ; The current Read LFN (must be ZP)

CurCHK_LFN:        .res 1   ; The current CHKIN/CHKOUT LFN

CurReadBufferPtr:  .res 2   ; Points to the current read buffer in FIO_RAM_BANK.
CurWriteBufferPtr: .res 2   ; Points to the current write buffer in FIO_RAM_BANK.

;----------------------------------------------------
; System Dictionary flags values
; Note: code relies on bit positions of flags.
;----------------------------------------------------
SD_65C02      = $80     ; MNEMONIC/PSEUDO OP applies to 65C02
SD_65C816     = $40     ; MNEMONIC/PSEUDO OP applies to 65C816
SD_OPCODE     = $01     ; Opcode doesn't change with addr mode (brk, cop)
SD_FIXUP      = $02     ; Check fixup table for this instruction ONLY if set
SD_IMM8       = $04     ; Immediate mode is always 8 bits


sd_flags:       .res 1  ; Initialized in AXAssemblerPass

;----------------------------------------------------
; 65C816 register sizes
;
; Note: code relies on bit positions of flags.
;----------------------------------------------------
RS_a16      = $80       ; Accumulator is 16 bits
RS_i16      = $40       ; Index regsiter is 16 bits

rs_flags:       .res 1  ; Initialized in AXAssemblerPass

; Used by AXPAssembleOpcode and AXIdentifyAddressMode, moved to zp to speed processing.
; Can be moved back to storage if necessary.
BaseOpcode_BIT = $20            ; Group 2. This is the base opcode in the System Dictionary, NOT the fixups table.
BaseOpcode_BRL = $82            ; Group 3

AXBaseOpcode:   .res 1       
AXSelector:     .res 1
AXGroup:        .res 1
AXAddrMode:     .res 1
AXFlags:        .res 1

TATemp0:        .res 2  ; Used in APIError
TAIsEOF:        .res 1  ; ReadChar's EOF flag


.if DEBUG=1
; DEBUGGING
; Aux JUMP Table
AuxInit       = $4000
AuxGetStatus  = $4003
AuxCharOut    = $4006
AuxStrOut     = $4009
AuxBStrOut    = $400c
AuxRegsOut    = $400f
AuxMemOut     = $4012
AuxTrace      = $4015
AuxTraceA     = $4018
AuxByteOut    = $401B
AuxWordOut    = $401E
AuxRDTIMOut   = $4021
.endif

        .segment "CODE"

; The first 12 bytes are vectors to various interfaces:

        jmp EDIT_vec            ; Call from X16-EDIT
        jmp BASIC_vec           ; Call from BASIC command line
        jmp SURPRISE1_vec       ; A future surprise!
        jmp SURPRISE2_vec       ; Another future surprise!

; The next 14 bytes are a signature string that X16-EDIT uses to
; confirm that this ROM code contains the assembler.
;
; This *MUST* start at $C00C:

assemble_signature:
        .byte "x16-assembler"
assemble_signature_end:
        .byte $00       ; Zero termination, in case we want to print it.

 ; This is what the signature is supposed to be:
 ;      .byte  $58,$31,$36,$2D,$41,$53,$53,$45,$4D,$42,$4C,$45,$52,$00

        .include "../build/libassembler.asm"


;------------------------------------------------------------
; CommonInit - Initialize common variables
;
; On entry: A-reg contains the contents of vec_flag (e.g. BASIC_VEC_FLAG or EDIT_VEC_FLAG)
;
;------------------------------------------------------------
CommonInit:
        sta vec_flag
        stz logical_flag
        stz ops_flags           ; Clear various flags and options
        stz mem_flags
        stz condasm_flags       ; Clear condasm flag (the other flag doesn't matter)
        stz AE_Error_flag
        stz write_error_flag
        lda #1                  ; Reserve the command channel
        sta nFilesOpen
        stz AsmFileOpen_flag    ; Set (non-zero) when the main source file has been opened.
        stz CurCHK_LFN          ; Clear the current CHKIN/CHKOUT LFN
        rts

;------------------------------------------------------------
; BASIC_vec - Call from the BASIC command line.
; ASM"code.asm"
;
; On entry:
;       KERNAL_R1 = file name length
;	KERNAL_R0 = file name address low,high
;------------------------------------------------------------
BASIC_vec:

        cld                     ; Just in case

; BASIC_vec initialization of flags and variables:
; This is done a bit earlier in BASIC_vec because we have to check for input
; paramaters and possibly set SURPRESS_OUTPUT flag before we produce output.

        lda #HOME_RAM_BANK      ; Make sure our variables are selected
        sta RAM_BANK_REG

        lda #BASIC_VEC_FLAG     ; Set only the BASIC_VEC_FLAG
        jsr CommonInit          ; Initialize common variables

        jsr TA_CopyCallToRAM    ; Set up the RAM copy of FarCalls table to our HOME RAM BANK

; Set the jiffy timer to zero:
        lda #0
        ldx #0
        ldy #0
        jsr FarSETTIM          ; Get the assembly start time.

; If KERNAL_buffer has $FE at BASIC_EC_RETURN and BASIC_EC_RETURN+1, set the SURPRESS_OUTPUT flag:
        stz RAM_BANK_REG        ; Select KERNAL RAM bank
        ldx BASIC_EC_RETURN+1
        ldy BASIC_EC_RETURN
        lda #HOME_RAM_BANK      ; Back to our RAM bank and variables
        sta RAM_BANK_REG

        cpy #MAGIC_BYTE_1       ; Is it the first magic byte?
        bne  @getfname          ; taken if not
        cpx  #MAGIC_BYTE_2      ; It it the second magic byte?
        bne @getfname           ; taken if not

; Got two consecutive magic bytes, so set the SURPESS_OUTPUT flag:

        lda ops_flags
        ora #SURPRESS_OUTPUT
        sta ops_flags

@getfname:

; Retieve the file name from BASIC, if one was provided:
        lda KERNAL_R1       ; File name len provided by BASIC
        bne @filename_ok

; No filename. This really shouldn't happen.

        jmp @nofile

@filename_ok:

; Copy file name from BASIC fname buffer in SYS RAM to our home RAM bank.
;
; NOTE: Use AsmFileNameLen and add our own zero terminator.   

        sta AsmFileNameLen  ; Save in our RAM bank
     
        ldy #0
@next0:
        lda (KERNAL_R0),y
        sta AsmFileName,y
        iny
        cpy AsmFileNameLen      ; Pointing past the end?
        bne @next0
@cont0:
        lda #0
        sta AsmFileName,y       ; zero terminate the file name

; Initialize CurFNameSavePtr:

; FSTAPtr is FilenameSaveTableAddress Pointer
        lda #<FSTAPtr    ; The pointer is incremeted to the next entry before use...
        sta CurFNameSavePtr                     ; ... so initialize to one entry "before" the start.
        lda #>FSTAPtr
        sta CurFNameSavePtr+1

        stz BytesWrittenBCD     ; Clear bytes out counter (3 BCD bytes)
        stz BytesWrittenBCD+1
        stz BytesWrittenBCD+2   

; Set the lower and upper bounds for .direct assembly from BASIC_vec (different from EDIT):

        lda #<DIRECT_LOWER_BASIC
        sta bound_lower
        ldx #>DIRECT_LOWER_BASIC
        stx bound_lower+1

        lda #<DIRECT_UPPER_BASIC
        sta bound_upper
         ldx #>DIRECT_UPPER_BASIC
        stx bound_upper+1

; Initialization for the TAOpen function:

        lda #SRC_START_LFN-1        ; reset handle tracker (it is incremented before first use)
        sta TAHandleTracker

        stz CurReadBufferPtr        ; LSB is always zero
        stz CurWriteBufferPtr       ; LSB is always zero

        lda ops_flags
        and #SURPRESS_OUTPUT
        bne @do_asm              ; Taken if set

        ldx #<assembling_msg
        ldy #>assembling_msg
        jsr StrOut_XY
        lda #CR
        jsr FarCHROUT

;----------------------------------------------------------
; Start the show from BASIC:
;----------------------------------------------------------
@do_asm:

; This uses the default file name string, which is AsmFileName.
        jsr AXAssemble      ; C=1 on error
        bcs @asm_error
        jmp @asm_success

@asm_error:
; There was an assembly error. TAError sets variables to simplify the return to EDIT:
; AE_ErrorCode, AE_ErrorLine.

; The FormatResponseMsg function puts the response message in KERNAL_buffer in RAM bank 0.
; We must copy it to strbuf to print it to the screen since our "FarXXXX" functions
; are in our home RAM bank:

        jsr FormatResponseMsg   ; Takes care of all the details
        bra @common_exit

; Issue the "no file" error message via FormatResponseMsg:
@nofile:

        lda #AXERRNOFILE 
        sta AE_ErrorCode 
        jsr FormatResponseMsg   ; Takes care of all the details

        bra @common_exit

; Prepare and display the success message:
@asm_success:
        lda #AXERRSUCCESS
        sta AE_ErrorCode
        jsr FormatSuccessMsg   ; Takes care of all the details

@common_exit:

        jsr ListResponseMsg
        jsr CloseFiles
        jsr FarCLRCHN           ; Restore I/O to keyboard and screen

; Save the error code and check byte:

        lda AE_ErrorCode
        stz RAM_BANK_REG        ; Select KERNAL RAM bank

        sta BASIC_EC_RETURN
        eor #$FF                ; Take one's complement
        sta BASIC_EC_RETURN+1

; Save the 3 "bytes written" BCD bytes (lsb to msb).
; The bytes are in our HOME RAM bank, the destination is KERNAL RAM BANK and 
; this code is just awkward.

        ldy #HOME_RAM_BANK

        sty RAM_BANK_REG
        lda BytesWrittenBCD 
        stz RAM_BANK_REG
        sta BASIC_BO_RETURN

        sty RAM_BANK_REG
        lda BytesWrittenBCD+1 
        stz RAM_BANK_REG
        sta BASIC_BO_RETURN+1

        sty RAM_BANK_REG
        lda BytesWrittenBCD+2
        stz RAM_BANK_REG
        sta BASIC_BO_RETURN+2

        sty RAM_BANK_REG        

; If output is supressed, skip printing message:
        lda ops_flags
        and #SURPRESS_OUTPUT    ; Output supressed?
        bne @BASIC_return       ; Taken if so.

; We ARE displaying output, so copy KERNAL_buffer to strbuff and print it:

; Copy KERNAL_buffer to strbuf so it can be printed by out StrOut_XY function:
        ldy #0
        ldx #HOME_RAM_BANK
@next3:
        stz RAM_BANK_REG        ; select KERNAL RAM bank
        lda KERNAL_buffer,y
        stx RAM_BANK_REG        ; select HOME RAM bank
        sta strbuf,y
        beq @cont3
        iny
        bne @next3
@cont3:

; Prepare to print the response message. First check if it should have an error prefix:

        lda AE_ErrorCode
        cmp #AXERRSUCCESS       ; "Success"?
        beq @show_msg           ; Taken if so

; Some kind of error, so show the BASIC_ErrPrefix before:

        ldx #<BASIC_ErrPrefix
        ldy #>BASIC_ErrPrefix
        jsr StrOut_XY

@show_msg:

        ldx #<strbuf
        ldy #>strbuf
        jsr StrOut_XY
        lda #CR
        jsr FarCHROUT

; Common exit for both assembly error and success:

@BASIC_return:
      
; We started with the time set to zero, so the stop it is the elapsed (delta) time:
        jsr FarRDTIM             ; Get the assembly start time.
        stz RAM_BANK_REG         ; Select KERNAL RAM BANK
        sta BASIC_DELTA_RETURN+0 ; Save the assembly delta time (3 bytes, LSB->MSB)
        stx BASIC_DELTA_RETURN+1
        sty BASIC_DELTA_RETURN+2
        lda #HOME_RAM_BANK
        sta RAM_BANK_REG
        rts

;------------------------------------------------------------
; SURPRISE1_vec
; SURPRISE2_vec
;   Future expansion.
;
;------------------------------------------------------------

SURPRISE1_vec:
SURPRISE2_vec:

        rts     ; for now

;------------------------------------------------------------
; EDIT_vec - Call from the X16-EDIT toolbox.
;------------------------------------------------------------

EDIT_vec:

; We use HOME_RAM_BANK for variable storage, ZP and LowRAM backup,
; and a KERNAL jump table:
        lda #HOME_RAM_BANK
        sta RAM_BANK_REG
        jsr TA_CopyCallToRAM            ; set up the RAM copy of JSRFAR table

; Save EDIT's ZP:
        jsr SaveZP

; Retieve the file name from EDIT, if one was provided:
        lda KERNAL_R0       ; File name len
        bne @filename_ok

; No filename. This can't happen if we are called from EDIT, but it *could* happen if
; someone calls EDIT_vec directly.

        jmp @nofile

@filename_ok:
; There is a file name so copy it to our RAM bank:

; Copy file name from KERNAL fname buffer in RAM bank 0 to our home RAM bank.
;
; NOTE: The file name passed from EDIT does NOT have a zero terminator.
;       Must use AsmFileNameLen and add our own zero terminator.   

        sta AsmFileNameLen  ; Save in our RAM bank

        ldy #0
        ldx #HOME_RAM_BANK
@next0:
        stz RAM_BANK_REG        ; Select KERNEL RAM bank
        lda KERNAL_buffer,y
        stx RAM_BANK_REG        ; Select our RAM bank
        sta AsmFileName,y
        iny
        cpy AsmFileNameLen      ; Pointing past the end?
        bne @next0
@cont0:
        lda #0
        sta AsmFileName,y       ; zero terminate the file name

; EDIT_vec initialization of flags and variables: 

;        lda #HOME_RAM_BANK      ; Make sure our variables are selected
;        sta RAM_BANK_REG

        lda #EDIT_VEC_FLAG      ; Set only the EDIT_VEC_FLAG
        jsr CommonInit          ; Initialize common variables


; Initialize CurFNameSavePtr:
; FSTAPtr is FilenameSaveTable Address Pointer
        lda #<FSTAPtr           ; The pointer is incremeted to the next entry before use...
        sta CurFNameSavePtr     ; ... so initialize to one entry "before" the start.
        lda #>FSTAPtr
        sta CurFNameSavePtr+1

        stz BytesWrittenBCD     ; Clear counter (3 BCD bytes)
        stz BytesWrittenBCD+1
        stz BytesWrittenBCD+2

; Set the lower and upper bounds for .direct assembly from EDIT_vec:

        lda #<DIRECT_LOWER_EDIT
        sta bound_lower
        ldx #>DIRECT_LOWER_EDIT
        stx bound_lower+1

        lda #<DIRECT_UPPER_EDIT
        sta bound_upper
        ldx #>DIRECT_UPPER_EDIT
        stx bound_upper+1

; Initialization for the TAOpen function:

        lda #SRC_START_LFN-1        ; reset handle tracker (it is incremented before first use)
        sta TAHandleTracker

        stz CurReadBufferPtr        ; LSB is always zero
        stz CurWriteBufferPtr       ; LSB is always zero

;----------------------------------------------------------
; Start the show from EDIT:
;----------------------------------------------------------

; This uses the default file name string, which is AsmFileName.
        jsr AXAssemble      ; C=1 on error
        bcc @asm_success

; There was an assembly error. TAError sets variables to simplify the return to EDIT:
; AE_ErrorCode, AE_ErrorLine.

        jsr FormatResponseMsg   ; Takes care of all the details

        lda AE_ErrorCode
        sta staged_KERNAL_R1

; Last_AE_ErrorLing tracks the line in the SOURCE file that was being assembled when the error occurred (usually in an include file).
; We use this value so the cursor will be placed on that line. The response message will state the actual include file and line number.

        lda Last_AE_ErrorLine       ; Error line LSB
        sta staged_KERNAL_R1+1
        lda Last_AE_ErrorLine+1     ; Error line MSB
        sta staged_KERNAL_R2
        stz staged_KERNAL_R2+1        ; Error line bits (23-17) (we only have 16 bits available)

        bra @EDIT_return

; Issue the "no file" error message via FormatResponseMsg:
@nofile:

        lda #AXERRNOFILE 
        sta AE_ErrorCode 
        jsr FormatResponseMsg   ; Takes care of all the details

        lda #$ff
        sta staged_KERNAL_R1         ; Return code: non-zero = error

        lda #1
        sta staged_KERNAL_R1+1        ; Error line LSB
        stz staged_KERNAL_R2          ; Error line middle byte
        stz staged_KERNAL_R2+1        ; Error line bits (23-17) (we only have 16 bits to give)
        bra @EDIT_return

; Set up to copy success message from ROM to the the to KERNAL fname buffer in RAM bank 0:
@asm_success:
        lda #AXERRSUCCESS
        sta AE_ErrorCode 
        jsr FormatSuccessMsg   ; Takes care of all the details

        stz staged_KERNAL_R1         ; Return code: zero = success

; Common exit for both assembly error and success:
@EDIT_return:

        jsr ListResponseMsg     ; Send the error/success message to the listing file, if one is being written.

  ; CloseFiles uses KERNAL registers, so we wait until AFTER this call to copy the "staged" KERNAL registers
  ; to the actual KERNAL registers:

        jsr CloseFiles
        jsr FarCLRCHN          ; Restore I/O to keyboard and screen


; Copy the staged KERNAL registers to the actual registers:

        lda staged_KERNAL_R1
        sta KERNAL_R1
        lda staged_KERNAL_R1+1        ; Error line LSB
        sta KERNAL_R1+1

        lda staged_KERNAL_R2          ; Error line middle byte
        sta KERNAL_R2
        lda staged_KERNAL_R2+1        ; Error line MSB (we don't use it)
        sta KERNAL_R2+1

        stz KERNAL_R3         ; Pointer to source file name for error (not used if success)
        stz KERNAL_R3+1         

        jsr RestoreZP

        jsr FarCLRCHN           ; Tidy up the I/O system

        rts

; These are production strings, keep them in the code.

success_msg:        .byte "success. ",$00               ; The trailing space is for extra information
byte_msg:           .byte " byte.",$00                  ; Note leading space. This is for 1 byte.
bytes_msg:          .byte " bytes.",$00                 ; Note leading space. This is for 0 or multiple bytes.
nofile_msg:         .byte "no file specified", $00
assembling_msg:     .byte "assembling...",$00
ErrorStrSuffix0:    .byte " in ",$00
ErrorStrSuffix1:    .byte ":line ",$00
BASIC_ErrPrefix:    .byte "***",$00                     ; Simple error indicator

; This is a string over several lines:
list_file_header:   .byte "commander x16 assembler v",ASM_VERS," listing file",CR,CR
                    .byte "line bk:addr    obj                   source ",CR
                    .byte "---- -- ---- ----------  --------------------------------",CR,$00
list_file_trailer:  .byte CR,"end of assembly.",CR,$00
list_assembling_file: .byte "---assembling file:",$00
list_assembling_src:  .byte "---assembling source:",$00
list_resuming_file:   .byte "---resuming file:",$00
list_resuming_src:    .byte "---resuming source:",$00

list_pass_prefix:     .byte CR,"---pass ",$00
list_pass_suffix:     .byte "---",CR,$00


;----------------------------------------------------------------------------
; BCD3_Str_NLZ - Converts 3 packed BCD digits to text with NO leading zeros
;
;   On Entry: bcd0, bcd0+1, bcd0+2 contain the packed BCD digits to convert (lsb to msb)
;             MemPtr points at a string buffer with at least 7 bytes (6 digits+NULL)
;   On Exit : String buffer contains 1-6 digits, plus NULL
;             Y-reg contains the number of characters in the buffer
;             X-reg is preserved, all other regs are destroyed
;
; Uses: Temp0
;----------------------------------------------------------------------------
; Temp0 is our flag for "found a non-zero digit".

BCD3_Str_NLZ:
        stz Temp0               ; No non-zero digits so far
        ldy #0                  ; Index into string buffer

;------------------------------------------------------
; Processes each nibble: 10 32 54
;                  bcd0+ 0  1  2
;------------------------------------------------------
        lda bcd0+2              
        lsr a                   ; nibble 5 
        lsr a
        lsr a
        lsr a
        clc
        adc #'0'
        cmp #'0'                ; Is it zero?
        bne @savedigit5         ; Taken if not

        bit Temp0               ; Digit is zero, should we skip it
        bpl @digit4             ; Taken if so

@savedigit5:
        dec Temp0               ; Found a non-zero digit
        sta (MemPtr),y          ; Save the digit
        iny

@digit4:
        lda bcd0+2              ; Get nibble 4
        and #$0f
        clc
        adc #'0'               
        cmp #'0'                ; Is it zero?
        bne @savedigit4         ; Taken if not

        bit Temp0               ; Digit is zero, should we skip it?
        bpl @digit3             ; Taken if so

@savedigit4:
        dec Temp0               ; Found a non-zero digit
        sta (MemPtr),y          ; Save the digit
        iny

@digit3:
        lda bcd0+1
        lsr a                   ; nibble 3 
        lsr a
        lsr a
        lsr a
        clc
        adc #'0'
        cmp #'0'                ; Is it zero?
        bne @savedigit3         ; Taken if not

        bit Temp0               ; Digit is zero, should we skip it
        bpl @digit2             ; Taken if so

@savedigit3:
        dec Temp0               ; Found a non-zero digit
        sta (MemPtr),y          ; Save the digit
        iny

@digit2:
        lda bcd0+1              ; Get nibble 2
        and #$0f
        clc
        adc #'0'               
        cmp #'0'                ; Is it zero?
        bne @savedigit2         ; Taken if not

        bit Temp0               ; Digit is zero, should we skip it?
        bpl @digit1             ; Taken if so

@savedigit2:
        dec Temp0               ; Found a non-zero digit
        sta (MemPtr),y          ; Save the digit
        iny

@digit1:

        lda bcd0                ; Get nibble 1
        lsr a
        lsr a
        lsr a
        lsr a
        clc
        adc #'0'
        cmp #'0'                ; Is it zero?
        bne @savedigit1         ; Taken if not

        bit Temp0               ; Digit is zero, should we skip it
        bpl @digit0             ; Taken if so

@savedigit1:
        dec Temp0               ; Found a non-zero digit
        sta (MemPtr),y          ; Save the digit
        iny

; We always save the last digit
@digit0:
        lda bcd0                ; Get nibble 0
        and #$0f
        clc
        adc #'0'
        sta (MemPtr),y          ; Save the digit
        iny
@done:
        lda #$00
        sta (MemPtr),y          ; Zero-terminate

        rts



;---------------------------------------------------------------
; FormatSuccessMsg 
;       Formats and copies the success response message back to
;       EDIT/BASIC via the KERNAL's RAM bank 0 buffer at $BF00.
;
; The message format:
;           SUCCESS. XXXXX bytes.
;   Where xxxx is 1-5 digits of the number of object bytes written
;   to memory/object file.
;
;   Prior   : n/a
;   On Entry: n/a
;   On Exit :  All regs destroyed
;---------------------------------------------------------------

; Set up to copy success string from our ROM bank to the KERNAL buffer in RAM bank 0

FormatSuccessMsg:

        lda #<success_msg       ; Fetch the success message
        sta MemPtr                      
        lda #>success_msg
        sta MemPtr+1

        stz RAM_BANK_REG        ; Select the KERNAL RAM bank
        ldy #0                  ; Y-reg indexes various source strings
        ldx #0                  ; X-reg indexes KERNAL_buffer
@esnext0:
        lda (MemPtr),y
        sta KERNAL_buffer,x
        beq @escont0
        iny
        inx
        bne @esnext0
@escont0:

; Add number of bytes written to the success message:

        lda BytesWrittenBCD 
        sta bcd0
        lda BytesWrittenBCD+1 
        sta bcd0+1
        lda BytesWrittenBCD+2
        sta bcd0+2

; Set destination:
; This shortcut only works because we assume LSB of KERNAL_buffer is zero:
        txa                      ; The KERNAL_buffer index is used as the...
        sta MemPtr               ; ... LSB of the BCD buffer pointer
        lda #>KERNAL_buffer
        sta MemPtr+1     
        jsr BCD3_Str_NLZ        ; Convert bytes written count to text (X-reg is preserved)

; On return, Y-reg is the number of characters added:
        tya
        clc
        adc MemPtr     ; This is the previous KERNAL_buffer index
        tax            ; New KERNAL_buffer index

; This is the byte/bytes adjustment:
        cpy #1          ; Was only 1 character added?
        bne @add_bytes  ; Taken if not
; Get that one character:
        dex             ; Points at last char
        lda KERNAL_buffer,x
        inx             ; Back at the end of the string
        cmp #ASCII_1    ; Is the character "1"?
        bne @add_bytes  ; Taken if NOT

; One byte was written, so select " BYTE." message:

        lda #<byte_msg         ; " BYTE." message
        sta MemPtr                      
        lda #>byte_msg
        sta MemPtr+1
        bra @copy_bytes_msg

@add_bytes:
; Zero on multiple bytes were written, so append " BYTES.":

        lda #<bytes_msg         ; " BYTES." message
        sta MemPtr                      
        lda #>bytes_msg
        sta MemPtr+1

@copy_bytes_msg:
        ldy #0                  ; Y-reg indexes source string
@esnext1:
        lda (MemPtr),y
        sta KERNAL_buffer,x
        beq @escont1
        iny
        inx
        bne @esnext1
@escont1:

        lda #HOME_RAM_BANK      ; Restore our working RAM bank
        sta RAM_BANK_REG

        rts

;---------------------------------------------------------------
; FormatResponseMsg 
;       Formats and copies the error response message back to
;       EDIT/BASIC via the KERNAL's RAM bank 0 buffer at $BF00.
;
; The message format:
;           <error msg> in <fname>:xxxx
;   Where xxxx is 1-4 digits of the line number.
;
; <file name> is truncated if the message would not fit on the
;             EDIT status bar (max 78 chars)
;
;   Prior   : n/a
;   On Entry: n/a
;   On Exit :  All regs destroyed
;---------------------------------------------------------------

; Set up to copy error string from our ROM bank to the KERNAL buffer in RAM bank 0

FormatResponseMsg:

        lda #HOME_RAM_BANK      ; Select our variable storage bank
        sta RAM_BANK_REG

        lda AE_ErrorCode        ; Fetch error code
        cmp #AXERRNOFILE        ; Special?
        bne @GetErrorStr        ; Taken if NOT

; AXERRNOFILE error is procssed differently as there is no line number

        stz RAM_BANK_REG        ; Select the KERNAL RAM bank
        ldx #0                  ; X-reg indexes KERNAL_buffer and source string
@nf_next:
        lda nofile_msg,x        ; This is from our ROM
        sta KERNAL_buffer,x     ; Going to KERNAL RAM
        beq @nf_cont
        inx
        bne @nf_next
@nf_cont:
        jmp @done

@GetErrorStr:
        jsr APIGetErrorStr      ; Fetch the error string in XY (in ROM)
        stx MemPtr                      
        sty MemPtr+1

        stz RAM_BANK_REG        ; Select the KERNAL RAM bank
        ldy #0                  ; Y-reg indexes various source strings
        ldx #0                  ; X-reg indexes KERNAL_buffer
@esnext0:
        lda (MemPtr),y
        sta KERNAL_buffer,x
        beq @escont0
        iny
        inx
        bne @esnext0
@escont0:

; If the line number is zero ("file not found"), skip everything else:

        lda #HOME_RAM_BANK      ; Get our variables back for a moment...
        sta RAM_BANK_REG
        lda AE_ErrorLine        ; Fast check for ErrorLine = zero...
        ora AE_ErrorLine+1
        stz RAM_BANK_REG        ; Select the KERNAL RAM bank
        bne @append_fname       ; Taken if non-zero
        jmp @done               ; Taken if ErrorLine is zero

@append_fname:
; Append " in " to the error string (y-reg points to the end of the error string)

        lda #<ErrorStrSuffix0
        sta MemPtr
        lda #>ErrorStrSuffix0
        sta MemPtr+1

        ldy #0  ; y indexes the source string
@esnext1:
        lda (MemPtr),y
        sta KERNAL_buffer,x
        beq @escont1
        iny
        inx
        bne @esnext1
@escont1:

; Append the saved filename to the error string:

        lda #HOME_RAM_BANK      ; These variables are in our RAM bank, so switch back...
        sta RAM_BANK_REG
        lda AE_ErrorFNamePtr
        sta MemPtr
        lda AE_ErrorFNamePtr+1
        sta MemPtr+1
        stz RAM_BANK_REG

        ldy #0  ; y indexes the source string
@esnext2:
        lda #HOME_RAM_BANK      ; The fname string is in our bank, so this is a bit ackward...
        sta RAM_BANK_REG
        lda (MemPtr),y
        stz RAM_BANK_REG
        sta KERNAL_buffer,x
        beq @escont2
        iny
        inx
        bne @esnext2
@escont2:

; Append ":" to the end of the response message:

        lda #':'
        sta KERNAL_buffer,x
        inx

; Append the error line number in decimal (digits: 3210)
; X-reg indexes the end of the KERNAL_BUFFER

        lda #HOME_RAM_BANK
        sta RAM_BANK_REG

        lda AE_ErrorLineDecimal
        sta bcd0                        ; ZP variable
        lda AE_ErrorLineDecimal+1 
        sta bcd0+1
        lda #$00                        ; Could always increase AE_ErrorLineDecimal if needed
        sta bcd0+2
        stz RAM_BANK_REG                ; Select KERNAL RAM bank

; Set destination:
; This shortcut only works because we assume LSB of KERNAL_buffer is zero:
        txa                      ; The KERNAL_buffer index is used as the...
        sta MemPtr               ; ... LSB of the BCD buffer pointer
        lda #>KERNAL_buffer
        sta MemPtr+1     
        jsr BCD3_Str_NLZ        ; Convert bytes written count to text (X-reg is preserved)

; On return, Y-reg is the number of characters added:
        tya
        clc
        adc MemPtr     ; This is the previous KERNAL_buffer index
        tax            ; New KERNAL_buffer index

@done:
;        lda #$00
;        sta KERNAL_buffer,x     ; Zero-terminate

        lda #HOME_RAM_BANK      ; Restore our working RAM bank
        sta RAM_BANK_REG

        rts

;---------------------------------------------------------------
; RestoreZP - Restores the assembler's ZP RAM area from ZPSaveBank
;   Prior   : n/a
;   On Entry: n/a
;   On Exit :  All regs destroyed
;---------------------------------------------------------------
RestoreZP:
        lda #HOME_RAM_BANK
        sta RAM_BANK_REG    ; Select the save bank

        ldx #0
@next:
        lda ZPSAVEADDR,x             ; In our storage
        sta ZPSTARTADDR,x            ; ZPSTARTADDR to ZPENDADDR-1 ($22-$xx)
        inx
        cpx #(ZPENDADDR-ZPSTARTADDR) ; Done?
        bne @next
        rts
;---------------------------------------------------------------
; SaveZP - Saves the assembler's ZP RAM area to ZPSaveBank
;   Prior   : n/a
;   On Entry: n/a
;   On Exit :  All regs destroyed
;---------------------------------------------------------------
SaveZP:
        lda #HOME_RAM_BANK
        sta RAM_BANK_REG    ; Select the save bank

        ldx #0
@next:
        lda ZPSTARTADDR,x            ; ZPSTARTADDR to ZPENDADDR-1 ($22-$xx)
        sta ZPSAVEADDR,x             ; In our storage
        inx
        cpx #(ZPENDADDR-ZPSTARTADDR) ; Done?
        bne @next
        rts

;-----------------------------------------------------
; StrOut_XY:
;
; SPECIAL "C64/CX16" VERSION OF THIS FUNCTION THAT OPERATES ON A POINTER IN X,Y
;
;   Prior   : Prepare screen and character set   
;   On Entry: X,Y = pointer to zero-terminated string
;                   to write to the screen
;   On Exit:  C = 0 - success
;                 1 - error
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;-----------------------------------------------------
StrOut_XY:
        pha
	phx
	phy
	stx MemPtr
	sty MemPtr+1
	   ldy #0
@next:
	lda (MemPtr),y
	beq @done
	jsr FarCHROUT
	bcs @done	; error
	iny
	bne @next	; falls through if y wraps around
@done:
	ply
	plx
        pla
	rts

;-------------------------------------------------------------------------
; SplitStr_XY:
;
; If the string is longer than "maximum string length" (A-reg),
; the string is split into two halves each with half of
; the maximum string length characters. A splat (*)
; is placed between the halves to indicate where characters
; were omitted.
;
; SPECIAL "C64/CX16" VERSION OF THIS FUNCTION THAT OPERATES ON A POINTER IN X,Y
;
;   Prior   : Ensure strbuf has room for the output string (see below).
;   On Entry: X,Y = pointer to zero-terminated string to split
;               A = maximum string length (an EVEN number).
;   On Exit:  The zero-terminated string is placed in strbuf. The
;             zero-terminated string can be "maximum string length" + 1
;             (for the splat) and the string has a zero termination.
;             Thus, strbuf must be AT LEAST "maximum string length" + 2
;             bytes.
;
;             All regs are preserved.
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
; Uses strbuf and two dedicated variables:
; Uses dedicated 1-byte variables: SplitStr_maxlen, SplitStr_strlen
;-------------------------------------------------------------------------
SplitStr_XY:

    sta SplitStr_maxlen
    stx MemPtr
    sty MemPtr+1

    jsr StrLen_XY           ; Check the string length
    sta SplitStr_strlen     ; Original string length
    cmp SplitStr_maxlen     ; Strlen ? max len
    beq @no_split           ; Strlen = max len (no split)
    bcs @split              ; Strlen > max len (split)

; Strlen <= max len (no split):
@no_split:
; The entire string will fit in the required length:
    ldy #0
@next_ns:
    lda (MemPtr),y
    sta strbuf,y
    beq @cont_ns
    iny
    bne @next_ns
@cont_ns:
    bra @exit

; Split the string into head and tail:
@split:
    lda SplitStr_maxlen     ; Get max len
    clc                     ; Divide the max len by 2
    ror a

; Copy this number of chars from the head of the string:

    tax
    ldy #0
@next_s:
    lda (MemPtr),y
    sta strbuf,y
    iny
    dex
    bne @next_s
@cont_s:
    lda #'*'
    sta strbuf,y  ; Indicate the split with a splat
    iny
    phy
    plx             ; X=index in the destination string

; Form the starting index for the tail:
; to form the starting index for the second  half.

    lda SplitStr_maxlen     ; Get max len
    clc                     ; Divide the max len by 2
    ror a
    sta Temp0
    lda SplitStr_strlen     ; Index of the end of the string
    sec
    sbc Temp0               ; A=index of the start of the tail
    tay
@next_t:
    lda (MemPtr),y
    sta strbuf,x
    beq @cont_t             ; Taken if null found.
    iny
    inx
    bne @next_t
@cont_t:

@exit:
    lda SplitStr_maxlen
    ldx MemPtr
    ldy MemPtr+1
    rts

;-------------------------------------------------------------------------
; StrLen_XY - Returns the length of a zero-terminated string
;
; SPECIAL "C64/CX16" VERSION OF THIS FUNCTION THAT OPERATES ON A POINTER IN X,Y
;
;   On Entry: X,Y = pointer to zero-terminated string
;   On Exit:  A = the length of the string
;             All other regs are preserved
;
; Uses 2 bytes of ZP: MemPtr and MemPtr+1
;
; Note:
;   The maximum measurable string length is 255 characters.
;   If a string is longer than 255 characters, 255 will be returned.
;-------------------------------------------------------------------------
StrLen_XY:
    stx MemPtr
    sty MemPtr+1

    ldy #0
; Look for the null byte at the end:
@1:
    lda (MemPtr),y
    beq @null_found
    iny
    bne @1
; String length overflow, return $255
    dey

@null_found:
    tya                 ; A-reg = length
    ldy MemPtr+1        ; Restore Y-reg (X-reg was not changed)
    rts

;-----------------------------------------------------
; FileExists
;
; Written by Tony3068 and posted on Discord:
; https://discord.com/channels/547559626024157184/629863245934755860/1359286644150108374
;
;   On Entry:   A   = length of name
;               X,Y = pointer to filename string
;   On Exit:  C = 0 - File exists
;                 1 - File does NOT exist
;             All other regs are preserved
;
; Note: The call setup is the same as SETNAM
;-----------------------------------------------------
FileExists:

    pha
    phx
    phy

; Open and then immediately close the file:
    jsr FarSETNAM 
    lda #FILE_EXISTS_LFN        ; LFN
    ldx #8                      ; Device
;    ldy #0                     ; Secondary
    tay                         ; Use LFN as secondary
    jsr FarSETLFS
    jsr FarOPEN
    lda #FILE_EXISTS_LFN       ; LFN
    jsr FarCLOSE

; Open the error channel and check the result:
    lda #0
    ldx #<Dummy_name
    ldy #>Dummy_name
    jsr FarSETNAM
    lda #15
    ldx #8
    ldy #15
    jsr FarSETLFS       ; All regs preserved
    jsr FarOPEN

    ldx #15
    stx CurCHK_LFN
    jsr FarCHKIN        ; Destroys all regs, but it is OK
    jsr FarGETIN
    cmp #'0'
    bne @NotFound
    jsr FarGETIN
    cmp #'0'
    beq @Found

@NotFound:
    jsr @flushchars
    ply
    plx
    pla
    sec
    rts

@Found:
    jsr @flushchars
    ply
    plx
    pla
    clc
    rts

; Clear the rest of the error message:
@flushchars:
    jsr FarGETIN
    cmp #13
    bne @flushchars
    lda #15
    jsr FarCLOSE
    rts


; dummy file name target
Dummy_name:
    .byte 0

        .segment "VARS"
;-----------------------------
; vec_flag values
;-----------------------------
EDIT_VEC_FLAG      = $80
BASIC_VEC_FLAG     = $40
SURPRISE1_VEC_FLAG = $20
SURPRISE2_VEC_FLAG = $10

vec_flag:         .res 1     ; Which vector (EDIT, BASIC, etc.) are we running from?

;----------------------------------------------------
; ops_flags values
;----------------------------------------------------
OBJ_FILE_SET     = $80    
OBJ_FILE_OPEN    = $40
LIST_FILE_SET    = $20
LIST_FILE_OPEN   = $10
NOADDR_SET       = $08    ; Object file does not have a two-byte load address
OBJ_WRITTEN      = $04    ; Object code has been written (affects .fill)
HEADER_WRITTEN   = $02    ; Header has been written to the object file
SURPRESS_OUTPUT  = $01    ; Don't print exit message in BASIC-vec (it will still be in KERNAL_buffer)

ops_flags:       .res 1      ; settings of various pseudo ops

;----------------------------------------------------
; mem_flags values
;----------------------------------------------------
ROM_BANK_ENABLED  = $80    ; rombank command active   
RAM_BANK_ENABLED  = $40    ; bank command active
DIRECT_SET        = $01    ; direct assembly to memory

mem_flags:        .res 1

;----------------------------------------------------
; condasm_flags values
;
; Code depends on b7 and b6 bit positions
;----------------------------------------------------
CONDASM_ENABLED   = $80    ; Conditional assembly is active (an .if/.else/.endif block is active)
CONDASM_SKIP      = $40    ; Skip assembly
CONDASM_ELSE      = $20    ; Else block is active

condasm_flags:  .res 1

; File I/O Buffering tables:
EOF_flag_table:         .res 7   ; Table of read buffer EOF flags zero-based from SRC_START_LFN
EOB_index_table_LSB:    .res 7   ; Table of read buffer EOB LSB indexes zero-based from SRC_START_LFN
EOB_index_table_MSB:    .res 7   ; Table of read buffer EOB MSB indexes zero-based from SRC_START_LFN
index_table_LSB:        .res 7   ; Table of "next byte" indexes for both read and write files zero-based from SRC_START_LFN 
index_table_MSB:        .res 7   ; Table of "next byte" indexes for read files zero-based from SRC_START_LFN (not used for write files)
TAReadCharEOB_flag:     .res 1   ; True if the char is the last one in the buffer

AsmFileName:      .res AXMaxLineSize   ; Name of the assembly source file
strbuf:           .res AXMaxLineSize   ; A string buffer that is used for various things.
AsmFileNameLen:   .res 1
AsmFileOpen_flag: .res 1               ; True of the main source file has been opened.

; Variables that enable displaying meaningful error message in a single line of 80 characters:
AE_Error_flag:       .res 1    ; True of the AE_Error information has been set
AE_ErrorCode:        .res 1    ; (AE=API Error)
AE_ErrorLine:        .res 2    ; Line in the file being assembled where the error occurred
Last_AE_ErrorLine:   .res 2    ; SOURCE file line where the last error occurred (used to put EDIT cursor on it)
AE_ErrorLineDecimal: .res 2
AE_ErrorFNamePtr:    .res 2    ; File being assembled when the error occurred
SplitStr_maxlen:     .res 1    ; Used by SplitStr_XY function
SplitStr_strlen:     .res 1    ; Used by SplitStr_XY function

FillLength:          .res 2    ; .fill pseudo op number of bytes to fill
FillValue:           .res 1    ; .fill pseudo op fill value

; Staged copies of KERNAL registers used by EDIT_vec to prepare them in advance of setting them.
staged_KERNAL_R0: .res 2
staged_KERNAL_R1: .res 2
staged_KERNAL_R2: .res 2
staged_KERNAL_R3: .res 2

FNameSaveTable:      .res (OPEN_FILES_MAX-1)*FNAME_SAVE_SIZE

FNameSaveTableSize = *-FNameSaveTable


        .segment "CODE"

        .include "api/x16/api.asm"

; Gather details of memory use. This must be at the very end of MAIN, after all code and INCLUDE files.

  .segment "ZEROPAGE"
  ZPENDADDR = *

  .segment "VARS"
  ZPSAVEADDR: .res ZPENDADDR-ZPSTARTADDR
  ZPSAVE_END = *
  LASTSTORAGE = *

 .segment "CODE"
 LASTCODE = *
 

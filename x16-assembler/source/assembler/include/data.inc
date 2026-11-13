; ************************************************************************************************
; ************************************************************************************************
;
;       Name:       data.inc
;       Purpose:    Assembler main data
;       Created:    11th March 2025
;       Author:     Paul Robson (paul@robsons.org.uk)
;
;	Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
;       April 2026 for the X16-Assembler in ROM project
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;                                       Constants
;
; ************************************************************************************************

        .segment "VARS"

AXMaxLineSize = 80
AXMaxIdentSize = 20
AXListByteCount = 4
AXMaxParams = 4

; Object and List logical file numbers (and secondary addresses)

; CX16 can only have 8 channels open at one time, but one is used for the command channel (LFN=15).
; This leaves LFNs/secondaries:  5,6,7,8,9,10,11,12,13,14 for obj, list, source, and include files
; The KERNAL ANDs the secondary with $0F to force it into 0-15.
; The secondary is the LFN, so we are constrained to use LFNs in the 0-15 range, but must omit the
; special values of 0,1, and 15.

; Note: File I/O buffer addresses are computed assuming LFNs are contiguous.

FILE_EXISTS_LFN =  5      ; Does not use a buffer
SRC_START_LFN   =  6      ; LFNs 6, 7, 8, 9, 10 and 11, 12 if OBJ and LIST are not used
WRITE_LFN_2     = 11      ; For OBJ and LIST
WRITE_LFN_1     = 12      ; For OBJ and LIST

; ************************************************************************************************
;
;                                       Global Data
;
; ************************************************************************************************

AXLeft:                                    ; left and right evaluation
                .res   3                           ; the bytes are LSB, MSB, undefined flag (bit 7)
AXLeft_byte3:   .res 1                        ; For limited support of 65C816 "long" (3-bytes)
                                            ; AXLeft+2 remains the undefined flag
AXRight:        .res   3

AXProgramCounter:                           ; program counter / RAM bank (ROM bank is stored in rom_bank)
        .res   3   

PCDirect:                                   ; program counter used by direct mode in a .virtual block
        .res   2   

PCDirectDelta:                             ; Difference between actual program counter and .virtual
        .res   2   

AXEvaluatePage:                             ; page # of last evaluated label.
        .res   1

AXLabelBuffer:                              ; buffer for label to be evaluated (ASCIIZ, U/C)
        .res   AXMaxIdentSize+1

AXTextParameter:                            ; buffer for text parameter.
        .res   AXMaxLineSize-2

AXCurrent:                                  ; address of currently selected identifier.
        .res   2

AXPass:                                     ; pass (1 or 2)
        .res   1       

AXLocalLabelID:                             ; local label ID counter.
        .res   2       
        
; ************************************************************************************************
;
;                   Frame data - this is saved when macro recursion occurs
;
; ************************************************************************************************

AXStartFrame:
;
;       The buffer is first so we can access parameters easily using the indices
;       in AXMParameters.
;
AXBuffer:                                   ; current line, ASCIIZ.
        .res   AXMaxLineSize+1                         

AXFileHandle:                               ; file handle           
        .res   1
AXLastCharacter:                            ; last character read.
        .res   1
;
;                               This block is made visible on error
;
AXErrorCode:                                ; error code goes here.
        .res   1
AXLineNumber:                               ; line number.
        .res   2               
AXLineNumberDecimal:                        ; line number in decimal.
        .res   2

AXProgramCounterStart:                      ; PCTR at instruction start.
        .res   2

PCDirectStart:                             ; Physical PCTR at instruction start.
        .res   2

AXMParamCount:                              ; number of macro parameters
        .res   1
AXMParameters:                              ; offset to parameter in AXBuffer
        .res   AXMaxParams+1

AXMPointer:                                 ; macro expansion pointer
        .res   2
        
AXListCount:                                ; byte count in list buffer
        .res   1
AXListBytes:                                ; those bytes
        .res   AXListByteCount

AXEndFrame:

AXFrameSize = AXEndFrame - AXStartFrame     ; calculate frame size.





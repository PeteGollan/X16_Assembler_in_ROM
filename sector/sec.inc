;
;---------------------------------------------------------------------------------------------
; sec.inc - Common definitions for the write and read sector programs.
;
; Pete Wyspianski (AKA Gollan)
; October 2026
; Ottawa, Canada
;---------------------------------------------------------------------------------------------

DEBUG = 1

.ifdef DEBUG
; Aux JUMP Table
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

FILE_EXISTS_LFN = 5     ; LFN for the FileExists function (must be unique)
SECTOR_FILE_LFN = 6     ; LFN for the sector file (read)
LOG_FILE_LFN    = 7     ; LFN for the log file (write)

;---------------------------------------------------------
; Data structures and types
;---------------------------------------------------------
; Max file name/path will be 80 characters.
KBD_BUF_SIZE=80         ; Keyboard input (can't be smaller than STR_BUF_SIZE)
STR_BUF_SIZE=80         ; Number conversions and filenames

SECTOR_SIZE = 512

DEFAULT_NSECTORS = 500

;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
CHRIN   = $FFCF ; In: a=char, Out: y-reg preserved
CHROUT  = $FFD2 ; In: n/a  Out: a=char, xy-regs preserved 
SETLFS  = $FFBA ; In: a=LFN, x=device (8), y=secondary (LFN) Out: all regs preserved
SETNAM  = $FFBD
LOAD    = $FFD5
GETIN   = $FFE4 ; In: n/a Out: a=char (or null), Out: xy-regs destroyed
OPEN    = $FFC0
CLOSE   = $FFC3
CLRCHN  = $FFCC ; In: n/a Out: ax-regs destroyed
READST  = $FFB7 ; In: n/a Out: a=status byte x-reg destroyed
CHKIN   = $FFC6 ; Set channel for char input
CHKOUT  = $FFC9 ; In: x=LFN Out: ax-regs destroyed
PLOT    = $FFF0 ; Set/Get cursor XY coordinates
EXTAPI  = $FEAB
MACPTR  = $FF44 ; In: a=bytes to read (0 for up to 512), xy=ptr to buffer, C=0 inc dest, C=1 don't inc dest Out: C=0 supported, xy=bytes read C=1 not supported

; EXTAPI sub-functions:
blink_enable = $14      ; x=0 blink, x!=0 no-blink

READST_EOF = $40    ; EOF bit

; ZP Bank Registers:
RAM_BANK_REG = $00
ROM_BANK_REG = $01


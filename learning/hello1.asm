;--------------------------------------------------------------------------
; hello1.asm - Get started with CX16 assembly language.
;
;
; To assemble: Press ctrl-F and select "A"
;              It will say "SUCCESS" if there are no errors.
;
; To run, exit EDIT with ctrl-x and then type: "sys $1000"
;
;
; IF THE REST OF THIS HEADER LOOKS SCRAMBLED, CHANGE EDIT TO ISO MODE:
;
;   PRESS CTRL-E AND THEN LEFT ARROW UNTIL THE MESSAGE AT THE BOTTOM
;   OF THE SCREEN SAYS "ISO" AND THEN PRESS ENTER.
;
;----------------------------------------------------------------------------

; Assemble direct to memory:
    .direct


;---------------------------------------------------------
; KERNAL
;---------------------------------------------------------
    CHROUT  = $FFD2 ; Character output to the screen


;---------------------------------------------------------
; Control Codes
;---------------------------------------------------------
    CR  = $0D   ; Puts the cursor on the next line.
    PUL = $0E   ; Puts the CX16 in PETSCII mixed-case mode.


;---------------------------------------------------------
; MAIN
;
; This is the start of the show!!!
;
;---------------------------------------------------------

    * = $1000       ; Start the program at address $1000

main:


    ldx #0          ; Use X-register as an index

_next:    
    lda hello_msg,x ; Get the next character of our message
    beq _cont       ; Branch take if we found the $00 at the end
    jsr CHROUT      ; This prints a character on the screen
    inx             ; Increment our index
    bne _next       ; Branch to print the next character


_cont:
    rts             ; We are done, go back to the BASIC prompt.


; You can change the message to whatever you want as long
; as it ends with $00.
;
; PUL - When we "print" this code, it puts the CX16 into
;       PETSCII Upper/lower case
; CR  - When we print this, it moves the cursor to the start
;       of the next line.

hello_msg:  .text PUL,"Hello CX16!",CR,CR,$00

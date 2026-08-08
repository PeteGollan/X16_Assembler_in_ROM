+--------------------------------------+
| Commander X16 Assembler in ROM v0.03 |
+--------------------------------------+
        Released August 7, 2026        

This is the manual for the 65C02 assembler integrated into the Commander X16 ROM.

The Commander X16 Assembler was written by Paul Robson (paul@robsons.org.uk) and published as MIT open source on Codeburg:

https://codeberg.org/paulscottrobson/x16-assembler

The assembler was integrated into ROM and had new features and pseudo-ops added by Pete Wyspianski (AKA Gollan petegollan@outlook.com)

The source code for the integrated assembler will be published before it is officially released.


+---------------+
| The Assembler |
+---------------+

The assembler can be called from EDIT (via Programming Toolbox), the BASIC command line, or a BASIC program.

The assembler accepts standard 65C02 mnemonics with common variations (e.g. ASL / ASL A), operating as a 2-pass assembler. 

Semicolon (;) delimits comments outside quoted strings.

Labels and identifiers are limited to 20 characters. Line lengths are limited to 80 characters.


+-------------+
| Expressions |
+-------------+

Expressions support the following using 16 bits :

- Binary operators with standard precedence : + - * / % & (and) | (or) ^ (exclusive or) >> << (shift right/left)
- Unary operators : - (parenthesis) * (program counter) > and < (lower and upper 8 bits), !label (returns bank number associated with the label or undefined)
- Terms : label, decimal, $[hexadecimal] %[binary] ‘[character code]’


+--------+
| Labels |
+--------+

A global label consists of an alphabetic character followed by a sequence of alphanumeric characters, underscore, at sign, and period. It may have a colon (:) at the end.

Labels beginning with underscore (_) or at sign (@) are "local labels" and only have scope between two global labels. Macro names are considered global labels.

A solitary global label is assigned the value of program counter.

Labels/identifiers can be anywhere on a line if ONE of the following is met:
    * Ends with a colon (:)
    * Is an assignment (<label> = <value>)
	* Is followed by a pseudo-op (mymac .macro or myvar .fill 2)
  	* A label/indentifier that does not meet ONE of these criteria must start in the first column


+------------------------+
| Invoking the Assembler |
+------------------------+

The assembler can be started from EDIT's Programming Toolbox, from the BASIC command line, or from a BASIC program. There are some differences.

--------------------------
EDIT's Programming Toolbox
--------------------------

With the source code open in EDIT, press ctrl-F to open the Programming Toolbox and then press "A" to start assembly.

When assembling from EDIT, restrictions on direct assembly locations protect EDIT and the system:

	System memory: $0801 to $9EFF
	RAM banks	 : $02-$09
	ROM banks    : $20-$FF

------------------
BASIC Command Line
------------------

Type:
  asm"<filename>"

When assembling from BASIC, restrictions on direct assembly locations protect the system:

	System memory: $0400 to $9EFF
	RAM banks	 : $02-$FF
	ROM banks    : $20-$FF

-------------
BASIC Program
-------------

See Appendix A for details on using the assembler from a BASIC program.

+-------------------+
| Assembler Options |
+-------------------+

The assembler is entirely controlled through pseudo operations.

-----------------
Pseudo Operations
-----------------

Pseudo-operations are:

+-------------------------+----------------------------------------------------------------------------------+
| Operation               | Function                                                                         |
|-------------------------|----------------------------------------------------------------------------------|
| .direct                 | Enables direct assembly to system RAM, banked RAM, and ROM                       |
| .rambank [index]        | Select RAM bank used in direct assembly in the range $A000 to $BFFF (also .bank) |
| .rombank [index]	  | Select ROM bank used in direct assembly in the range $C000 to $FFFF              |
| .object  "file"         | Enables assembly output to the specified file (also .obj)                        |
| .noaddr	          | Omits the address header in the .object file                                     |
| .include "file"         | Include a source file                                                            |
| .binary "file"          | Include binary file (also .incbin)                                               |
| .list "file"            | Enables listing output to the specified file                                     |
| .byte [values]          | Adds a sequence of bytes (also .db)                                              |
| .word [values]          | Adds a sequence of words in low/high order (also .dw)                            |
| .text [string|byte]     | Sequence of quoted strings (ASCII) or bytes, can be mixed                        |
| .petscii [string|byte]  | Same as .text, except it interprets quotes strings as mixed case PETSCII         |
| .fill count[,value]     | Allocates an area of memory and optionally fills with specified value (also .ds) |
| .align value            | Puts on align byte boundary                                                      |
| .macro name             | Define macro (also name .macro) (see below)                                      |
+-------------------------+----------------------------------------------------------------------------------+

-------
.direct
-------

Direct can be used with .object, caution is advised when changing the program counter (using `*=`) as subsequent code sent to the file
will have the new origin. This **can** be used to create relocatable code.

---------------------
.rambank and .rombank
---------------------

Direct mode .direct must be enabled to use these operations. When [index] is omitted, the next RAM or ROM bank is selected.
.rambank and .rombank do **not** change the program counter. This must be done explictly:

	.direct
	.rambank $5	; Sets RAM bank to $5
	*=$A000		; The instructions will be assembled to RAM bank $5, starting at $A000.
	lda #foo
	sta bar		

	.rambank	; Increments the set RAM bank. In this example, it sets RAM bank to $6.
	*=$A010		; The instructions will be assembled to RAM bank $6, starting at $A010.
	asl
	sta moo

-------------------
.object and .noaddr
-------------------

By default, .object (or .obj) creates a file that has an address header and is use with LOAD:

	Source file: .obj "foo.prg"
	...
	LOAD "foo.prg",8,1


The .noaddr option eliminates the load address and requires BLOAD:

	Source file: .obj "moo.bin"
	...
	BLOAD "moo.bin",8,1,$A000

-----
.fill
-----

Fill .fill accepts a count in the range 0-255 and an optional value parameter, also in the range 0-255.

Fill has two modes of operation:

Prior to code being generated, fill advances the program counter by the given count in .direct and does not write anything to an object file. This is how .fill is used to resever variables in zero page and other locations:

	
		* = $22		; zero page
	var1:	.fill 2
	var2:	.fill 4
	
After code has been generated, fill emits the number of bytes specified by count, starting at the program counter. The default fill value is zero, but an optional fill value may be specified:

		* = $1000
	main:	lda #$5a
			ldx #$a5
			rts
	var5:	.fill 2,$aa		; Produces: $aa $aa
	var6:	.fill 1			; Produces: $00
	var7:	.fill 4,$99		; Produces: $99 $99 $99 $99 
	

------
Macros
------

The the identifier can appear either *before* or *after* the .macro pseudo-op:

	.macro foo
	foo .macro	; 64TASS compatibility

Text substitution macros are permitted to a depth of 4 or 5, depending on remaining identifier storage space.

Macro names are global labels and thus reset the local label stack.

+---------------|-----------------------------------------+
| Operation     | Function                                |
| ------------- | --------------------------------------- |
| .macro name   | Defines a macro (also name .macro)      |
| .endm         | Ends a macro                            |
| \1 \2 \3      | Text substitutions of up to 3 arguments |
+---------------|-----------------------------------------+

Macro example:

	.macro set16	; addr/label, 16-bit value
	lda 	#(>\2)
	sta 	\1
	lda 	#(<\2)
	sta 	1+(\1)
	.endm


+--------------------------------+
| Source Code Character Encoding |
+--------------------------------+

The assembler can process source code in either ASCII or PETSCII upper case. Typical mixed-case assembly code can be written in ASCII by selecting EDIT's ISO mode.
In ASCII, identifiers and labels can be in mixed upper/lower case and can include underscore (_), at sign (@) and period (.). The .text pseudo-op is used to produce ASCII strings, and
the .petscii pseudo-op is used to produce mixed case PETSCII strings.

PETSCII upper case can also be used, but there are some quirks. The underscore is now a PETSCII left arrow (←).
The .text pseudo-op must be used to produce PETSCII strings, as it doesn't transcode.

PETSCII mixed case can be used to create assembly source code, however identifiers, mnemonics, and pseudo-ops must be written in lower case.


+-----------------+
| Assembly Errors |
+-----------------+

The first error stops assembly and produces a message that includes the file name and line number of the error. In EDIT, an error in an include file will show the name and line number of the error file and the EDIT cursor will be placed on the line in the current source file that, ultimately, includes the error file. In other words, in the case of deeply nested include files, the EDIT cursor will be placed on the top include. For file names longer than 32 characters, the assembler splits the displayed file name into two 17-character halves with an asterix (*) in the middle.


+--------------------+
| Future Development |
+--------------------+

Some contemplated future development:

* Performance optimizations
* Conditional assembly
* Support for relocatable code (e.g. ".virtual")
* Symbol/identifier table listing option
* .rambank and .rombank increment rollover to the next available bank
* A built-in IDE (Integrated Development Environment)

Please share you ideas and suggestions. Which of these would you like to see first?

+---------------------------------------------+
| Appendix A - Using ASM from a BASIC Program |
+---------------------------------------------+

The sample program "asmbasic.bl" demonstrates the use of the assembler from a BASIC program. You can call the assembler with a file name:

  10 asm"<filename>"

In this case, the assembler with display it's usual messages and return control to the BASIC program.

The assembler output can be surpressed by setting two "magic bytes" prior to calling the assembler:

  ASM_EC = $BFFE : REM ERROR CODE
  ASM_CC = $BFFF : REM CHECK CODE

  ASM_MB1 = $FA : REM Magic bytes to supress output
  ASM_MB2 = $FB

  BANK 0
  POKE ASM_EC,ASM_MB1		: REM supress asm output
  POKE ASM_EC+1,ASM_MB2

To ensure that assembler output is NOT surpressed, these two bytes can be set to $FF prior to calling the assembler:

  BANK 0
  POKE ASM_EC,$FF		: REM ensure ASM output is shown
  POKE ASM_EC+1,$FF

The assembler error code and check code can be retrieved after assembly:

  BANK 0
  EC = PEEK(ASM_EC)
  CC = PEEK(ASM_CC)

The check code is the one's complement of the error code. It is provided as an optional confirmation that the error code is valid:

  IF (NOT(CC) = EC) GOTO CC_VALID

See Appendix B for a list of error codes.

The assembler makes the text of the response string available to a BASIC program in the KERNAL_buffer in RAM bank 0. This is a null-terminated string that is a maximum of 80 characters long. See the "asmbasic.bl" program subroutine "asm_response" for sample code that retrieves this string. The assembler also makes the "bytes" count available. An example of retrieving this value is  provided in the "asm_response" subroutine.


+--------------------------+
| Appendix B - Error Codes |
+--------------------------+

+-----+---------------------------------------------------------+
|Code |                   Error            			|
|-----|---------------------------------------------------------|
| $00 | Assembly success (not an error)     			|
| $01 | General syntax error					|
| $02 | Bad identifier, missing/too long			|
| $03 | Divide by zero						|
| $04 | Value of an identifier has changed			|
| $05 | Source file not found					|
| $06 | Undefined identifier					|
| $07 | Relative branch range					|
| $08 | Address mode not supported in 65C02			|
| $09 | Bad expression						|
| $0A | Line too long						|
| $0B | Too many macro parameters				|
| $0C | Bad expansion parameter					|
| $0D | Out of memory						|
| $0E | Object file error (open or write)			|
| $0F | Object file already specified (multiple .obj) 		|
| $10 | List file error (open or write)				|
| $11 | List file already specified (multiple .list)		|
| $12 | Direct assembly address out of range			|
| $13 | .bank requires .direct 					|
| $14 | .rombank requires .direct 				|
| $15 | Bank number out of range (for RAM or ROM banks)		|
| $16 | .rambank required for direct assembly to $A000-$BFFF	|
| $17 | .rombank required for direct assembly to $C000-$FFFF	|
| $18 | .macro requires an identifier				|
| $19 | .macro identifier already exists			|
| $1A | Too many nested files					|
|.....|.......							|
| $E1 | Source file not specified (e.g. ASM"")			|
+-----+---------------------------------------------------------+


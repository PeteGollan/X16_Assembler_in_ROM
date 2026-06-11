# **Commander X16 Assembler in ROM v0.01**

This is the specification for the 65C02 assembler integrated into the Commander X16 ROM.

The Commander X16 Assembler was written by Paul Robson (paul@robsons.org.uk) and published as MIT open source on Codeburg:

https://codeberg.org/paulscottrobson/x16-assembler

The assembler was integrated into ROM and had new features and pseudo-ops added by Pete Wyspianski (AKA Gollan petegollan@outlook.com)

The source code for the integrated assembler will be published before it is officially released.


## The Assembler

The assembler accepts standard 65C02 mnemonics with common variations (e.g. ASL / ASL A), operating as a 2-pass assembler. 

Labels must start at the beginning of a line and may end with a colon (:).

Semicolon (;) delimits comments outside quoted strings.

Labels and identifiers are limited to 20 characters. Line lengths are limited to 80 characters.

## Expressions

Expressions support the following using 16 bits :

- Binary operators with standard precedence : + - * / % & (and) | (or) ^ (exclusive or) >> << (shift right/left)
- Unary operators : - (parenthesis) * (program counter) > and < (lower and upper 8 bits), !label (returns bank number associated with the label or undefined)
- Terms : label, decimal, $[hexadecimal] %[binary] ‘[character code]’

## Labels
A global label consists of an alphabetic character followed by a sequence of alphanumeric characters or underscore.

Labels beginning with underscore (_) or at sign (@) are "local labels" and only have scope between two global labels. Macro names are considered global labels.


## Invoking the Assembler

The assembler can be started from either EDIT's Programming Toolbox or from the BASIC command line. There are some differences.

### EDIT's Programming Toolbox

With the source code open in EDIT, press ctrl-F to open the Programming Toolbox and then press "A" to start assembly.

When assembling from EDIT, restrictions on direct assembly locations protect EDIT and the system:

	System memory: $0801 to $9EFF
	RAM banks	 : $02-$09
	ROM banks    : $20-$FF

### BASIC Command Line

Type:
`asm"<filename>"`

When assembling from BASIC, restrictions on direct assembly locations protect the system:

	System memory: $0400 to $9EFF
	RAM banks	 : $02-$FF
	ROM banks    : $20-$FF

## Assemebler Options

The assembler is entirely controlled through pseudo operations.

## Pseudo Operations

Pseudo-operations are:

| Operation               | Function                                                                         |
| ----------------------- | -------------------------------------------------------------------------------- |
| .direct                 | Enables direct assembly to system RAM, banked RAM, and ROM                       |
| .rambank [index]        | Select RAM bank used in direct assembly in the range $A000 to $BFFF (also .bank) |
| .rombank [index]	      | Select ROM bank used in direct assembly in the range $C000 to $FFFF              |
| .object  "file"         | Enables assembly output to the specified file (also .obj)                        |
| .noaddr	              | Omits the address header in the .object file                                     |
| .include "file"         | Include a source file                                                            |
| .binary "file"          | Include binary file (also .incbin)                                               |
| .list "file"            | Enables listing output to the specified file                                     |
| .byte [values]          | Adds a sequence of bytes (also .db)                                              |
| .word [values]          | Adds a sequence of words in low/high order (also .dw)                            |
| .text [string\|byte]    | Sequence of quoted strings (ASCII) or bytes, can be mixed                        |
| .petscii [string\|byte] | Same as .text, except it interprets quotes strings as mixed case PETSCII         |
| .fill [count]           | Allocates an area of memory but doesn't assemble anything there                  |
| .align [value]          | Puts on align byte boundary                                                      |
| .macro name             | Define macro (also name .macro) (see below)                                      |

## .direct

Direct can be used with .object, caution is advised when changing the program counter (using `*=`) as subsequent code sent to the file
will have the new origin. This **can** be used to create relocatable code.

## .rambank and .rombank

Direct mode (`.direct`) must be enabled to use these operations. When [index] is omitted, the next RAM or ROM bank is selected.
`.rambank` and `.rombank` do **not** change the program counter. This must be done explictly:

	.direct
	.rambank $5	; Sets RAM bank to $5
	*=$A000		; The instructions will be assembled to RAM bank $5, starting at $A000.
	lda #foo
	sta bar		

	.rambank	; Increments the set RAM bank. In this example, it sets RAM bank to $6.
	*=$A010		; The instructions will be assembled to RAM bank $6, starting at $A010.
	asl
	sta moo

## .object and .noaddr

By default, `.object` (or `.obj`) creates a file that has an address header and is use with `LOAD`:

	Source file: .obj "foo.prg"
	...
	LOAD "foo.prg",8,1


The `.noaddr` option eliminates the load address and requires `BLOAD`:

	Source file: .obj "moo.bin"
	...
	BLOAD "moo.bin",8,1,$A000


## Macros

The the identifier can appear either *before* or *after* the .macro pseudo-op:

	.macro foo
	foo .macro	; 64TASS compatibility

Note that if the identifier appears *before* the .macro, it must start at the beginning of the line.

Text substitution macros are permitted to a depth of 4 or 5, depending on remaining identifier storage space.

Macro names are global labels and thus reset the local label stack.

| Operation     | Function                                |
| ------------- | --------------------------------------- |
| .macro name   | Defines a macro (also name .macro)      |
| .endm         | Ends a macro                            |
| \1 \2 \3      | Text substitutions of up to 3 arguments |

### Example:

	.macro set16	; addr/label, 16-bit value
	lda 	#(>\2)
	sta 	\1
	lda 	#(<\2)
	sta 	1+(\1)
	.endm

## Source Code Character Encoding

The assembler can process source code in either ASCII or PETSCII upper case. Typical mixed-case assembly code can be written in ASCII by selecting EDIT's ISO mode.
In ASCII, identifiers and labels can be in mixed upper/lower case and can include underscore (_) and at sign (@). The .text pseudo-op is used to produce ASCII strings, and
the .petscii pseudo-op is used to produce mixed case PETSCII strings.

PETSCII upper case can also be used, but there are some quirks. The underscore is now a PETSCII left arrow (←).
The .text pseudo-op must be used to produce PETSCII strings, as it doesn't transcode.

PETSCII mixed case can be used to create assembly source code, however identifiers, mnemonics, and pseudo-ops must be written in lower case.

## Assembly Errors

The first error stops assembly and produces a message that includes the line number of the error. If an error occurs in an include file,
the displayed line number will be for the .include line. If there is also a listing file, it will show the actual error line number in the included file.
The error line number can also be found by loading the include file into EDIT and assembling it, or by assembling the include file at the BASIC prompt.

## Future Development

Some contemplated future development:

* Performance optimizations
* Conditional assembly
* Support for relocatable code (e.g. ".virtual")
* Symbol/identifier table listing option
* `.rambank` and `.rombank` increment rollover to the next available bank

Your ideas and suggestions are welcome and encouraged.
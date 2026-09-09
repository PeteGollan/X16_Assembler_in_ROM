# **TEST RELEASE "i2" of Commander X16 Assembler in ROM v0.04**
September 9, 2026

This repository contains demo KERNAL ROMs that have the X16-Assembler in ROM integrated.

## Contents

|        File        |                                     Description                                         |
|--------------------|-----------------------------------------------------------------------------------------|
|**r49_ti2.bin**     | R49 KERNAL ROM with Assembler, test version "i2"                                        |
|**r49cwd_ti2.bin**  | R49 KERNAL ROM with Assembler plus Calypso support with driver (cwd), test version "i2" |
|**ad1.asm**         | Assembler demo #1                                                                       |
|**asmbasic.bl**     | BASLOAD program demonstrates interacting with ASM from a BASIC program                  |
|**asmdelta.bl**     | BASLOAD program demonstrates retrieving assembly time                                   |
|**asmdelta.prg**    | Compiled version of the program can be used to view assembly time                       |
|**hello1.asm.bl**   | Sample assembly program to introduce the assembler and CX16 assembly programming        |
|**basic_header.bin**| BASIC stub for use with .binary (see the .binary section in MANUAL.txt)                 |
|**prev_ROMs**       | Directory contains previously released ROMs                                             |
|**testing**         | Directory contains programs that were used to test various assembler functions          |
|**MANUAL.txt**      | The Assembler-in-ROM manual                                                             |

  (More assembler demos will be released)

Note:
* ROM files have their original filenames embedded. Search "X16-Assembler" with a hex editor to check filename.

## Changes from the "ti1" ROMs:
* Help text shows the name of the ASM test ROM
* Byte at offset $43FCF changed from $FF to $00 to match prior padding bytes.

## Changes from the "ti" ROMs:
* Assembler version 0.04 (no change)
* Test ROM version "i1"
* Mitigates a bug in the CALYPSO driver
* Standard test ROM re-released as it also includes the CALPYSO mitigation

## Changes from the "th" ROMs:
* Assembler version 0.04
* Test ROM version "i"
* NO CALPYSO SUPPORT for this release (See "Calypso Support" below)
* Significantly improved assembly performance on hardware
* Assembly time is available when the assembler is called from a BASIC program or the BASIC command line. See asmdelta.bl and asmdelta.prg.
* Assembler now uses RAM banks 1 and 2
* Sample program "hello1.asm" is provided as an introduction to CX16 assembly programming
* The CX16-Assembler manual is now named "MANUAL.txt" and is written in plain text.

## Changes from the "tg" ROMs:
* Assembler version 0.03
* The number of object bytes created is now reported on successful assembly
* Improved error reporting:
  * Error messages include the name of the error file and line number
  * The status message and error code are available when the assembler is called from a BASIC program
  * Assembler output can be surpressed when the assembler is called from a BASIC program
  * See README for details
* Listing file improvements:
  * Expanded error messages
  * More details of the assembly process
  * Listing of .fill and .binary pseudo-ops are fixed
* Improvements to the handling of labels/identifiers:
  * Labels/identifiers can now be anywhere on a line if ONE of the following is met:
    * Ends with a colon (:)
    * Is an assignment (<label = <value>)
    * Is followed by a pseudo-op (mymacro .macro or myvar .fill 2)
  * A label/indentifier that does not meet these criteria must start in the first column
  * See README for details
* Improved include file handling:
  * Supports up to 6 levels of nested include files (reduced to 4 if both .object and .list are used)
* Added directory "testing" that contains testing samples.

## Changes from the "tf" ROMs:

* Assembler version 0.02.
* Fixed an issue that prevented OBJ and LIST files from being created in the r49_tf ROM.
* Added an optional fill value option to the `.fill` pseudo op (see README).
* Added file save checks to the Programming Toolbox for both BASLOAD and ASSEMBLER.


## How to Use the KERNAL ROMs

Rename either stock or Calypso ROM to ROM.bin and use CX16-Update to flash your CX16/OtterX.

If you have a development system with a ZIF socket, you can create a ROM with a programmer.

## How to Use AD1.ASM:

From the BASIC command line:
```
  ASM"AD1.ASM"
  RUN
```

From EDIT:
  * Open ad1.asm (e.g. EDIT"AD1.ASM")
  * If necessary: press ctrl-E and then arrow keys to select "ISO"
  * Press ctrl-F to open the Programming Toolbox
  * Press "A" to start assembly
  * Exit EDIT
  * Type "run"

## How to Use ASMBASIC.BL:

From the BASIC command line:
```
BASLOAD"ASMBASIC.BL"
RUN
```

From EDIT:
  * Open ASMBASIC.BL (e.g. EDIT"ASMBASIC.BL")
  * If necessary: press ctrl-E and then arrow keys to select "ISO"
  * Press ctrl-F to open the Programming Toolbox
  * Press "B" to start BASLOAD compilation
  * Exit EDIT
  * Type "run"

## How to Use ASMDELTA.BL:

ASMDELTA is used to display the assembly time in seconds after the assembler is run from the BASIC command line.

From the BASIC command line:
```
BASLOAD"ASMDELTA.BL"
RUN
```
Alternatively:
```
^ASMDELTA.PRG
```


## Calypso Support
Calypso support has been omitted for the "ti" release. I am evaluating an incompatibility between the Calypso
driver and the performance improvements that have been added to the assembler. I will continue Calypso support
if a reasonable solution can be found.

## Next Steps
Please read MANUAL.txt for detailed information on the assembler. Please modify the demo and test programs and
show what you can do.

## Development of the Assembler in ROM Project
All testing and debugging of the Assembler in ROM project is done on hardware (OtterX #133). All sample and test
programs were developed on hardware using EDIT.

## Future development

Focus for the *next* release will be:
  * Conditional assembly features
  * Memory optimization for the symbol/indentifier table
  * MANUAL.txt formatted for use in EDIT

## Feedback
Please share any issues you find and let me know what you think:

Pete Wyspianski (AKA Gollan petegollan@outlook.com and on Discord)
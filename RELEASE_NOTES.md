# **TEST RELEASE of Commander X16 Assembler in ROM v0.03**

This repository contains demo KERNAL ROMs that have the X16-Assembler in ROM integrated.

## Contents

|        File        |                                     Description                                       |
|--------------------|---------------------------------------------------------------------------------------|
|**r49_th.bin**      | Stock KERNAL ROM with Assembler, test version "h"                                     |
|**r49cwd_th.bin**   | KERNAL ROM with Assembler plus Calypso support with driver (cwd), test version "h"    |
|**ad1.asm**         | Assembler demo #1                                                                     |
|**asmbasic.bl**     | BASLOAD program demonstrates interacting with ASM from a BASIC program                | 
|**prev_ROMs**       | Directory contains previously released ROMs                                           |
|**testing**         | Directory contains programs that were used to test various assembler functions        |

  (More assembler demos will be released)

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

Rename either stock or Calypso ROM to ROM1.bin and use CX16-Update to flash your CX16/OtterX.

If you have a development system with a ZIF socket, you can create a ROM with a programmer.

## How to Use ad1.asm:

Copy ad1.asm to your CX16/OtterX

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

## How to Use asmbasic.bl:

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

## Next Steps
Please modify the demo and test program and show what you can do.

## Development of the Assembler in ROM Project
All testing and debugging of the Assembler in ROM project is done on hardware (OtterX #133). All sample and test programs were developed on hardware using EDIT.

## Feedback
Please share any issues you find and let me know what you think:

Pete Wyspianski (AKA Gollan petegollan@outlook.com and on Discord)
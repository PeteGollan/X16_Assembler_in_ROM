# **DEMO RELEASE of Commander X16 Assembler in ROM v0.02**

This repository contains demo KERNAL ROMs that have the X16-Assembler in ROM integrated.

## Contents

  r49_tg.bin - Stock KERNAL ROM with Assembler

  r49cwd_tg.bin - KERNAL ROM with Assembler plus Calypso support with driver (cwd) version "tf".

  ad1.asm - Assembler demo #1.
  
  (More assembler demos will be released.)

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

From BASIC:
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

## Next Steps
You are encouraged to modify ad1.asm and show it off.

## Feedback
Please share any issues you find and let me know what you think:

Pete Wyspianski (AKA Gollan petegollan@outlook.com and on Discord)
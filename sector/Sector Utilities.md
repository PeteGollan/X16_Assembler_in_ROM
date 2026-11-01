# Sector Utilities v0.1

The sector utilities are a pair of Commander X16 assembly language programs that are intended to help investigate unexpected operation of CX16 file IO functions. They are only relevant for testing on hardware. They are **NOT** compatible with the Calypso accessory.

## wsec.prg
Writes a data file containing a specified number of 512 byte sectors. Run with:
```
^wsec.prg
```
Pressing RETURN uses default settings (marked with an asterisk).You can exit at any prompt by pressing ESC. During file creation, you can exit by pressing ESC or ctrl-C.

## rsec.prg
Reads data files created by wsec and compares the read data with the expected data. The program generates of log of differences. rsec can read the data using either CHRIN or MACPTR

```
^rsec.prg
```
Pressing RETURN uses default settings (marked with an asterisk).You can exit at any prompt by pressing ESC. The CHRIN/MACPTR prompt determines which CX-16 KERNAL call will be used to read the sectors. You are asked for the name of the data file and the log file. During file read, you can exit by pressing ESC or ctrl-C. 

## Building the Sector Utilities
The programs were created using ca65. On Windows, build.bat builds both programs from a Command Shell:
```
./build.bat
```
To build on other operating systems, use the build command lines in build.bad file. The programs can be built on the CX16 with the X16-Assembler, but require some pseudo ops changes (e.g. .res -> .fill).

## Included Data Files
Two data files are included in the Sector directory. They can be used explore how the log file presents errors:

```
bad.dat
  * Three bad sectors:
	* Sector $0001, third word $0001 -> $d0a7
    * Sector $0002, index $111 $00 -> $FE
    * Sector $0003, last $82 bytes completely mangled (copied from sector 4)

bigbad.dat
 * Sector $0005 has 512 bad bytes
```

## Sector Data File Format

The sector data file contains 512-byte sectors. The second word of each sector (index $02 and $03) contains a simple checksum. The remaining words (255) are the hexidecimal sector number in little-endian format (lsb,msb). This format is intended to highlight the type of error where the wrong sector is read or parts of a different sector appear.

# Feedback

I welcome you feedback, questions, and findings.
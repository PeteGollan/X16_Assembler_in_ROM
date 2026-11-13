# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		common.make
#		Purpose :	Common make stuff.
#		Date :		11th March 2025
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

# *******************************************************************************************
#
#										Configuration
#
# *******************************************************************************************

PYTHON = python3
MAKE = make --no-print-directory 
EMULATOREXEC = x16emu

# *******************************************************************************************
#
#										Directories
#
# *******************************************************************************************
#
#		Home of the X16 emulator binary and rom.bin
#
X16EMUDIR = /aux/builds/x16-emulator/
#
#		Root directory of repo
#
ROOTDIR =  $(dir $(realpath $(lastword $(MAKEFILE_LIST))))../
#
#		Stores executables
#
BINDIR = $(ROOTDIR)bin/
#
#  		Artefacts of builds.
#
BUILDDIR = $(ROOTDIR)build/
#
#		Where the build environment files are (e.g. like this)
#
BUILDENVDIR = $(ROOTDIR)build_env/
#
#
#
CONFDIR = $(ROOTDIR)conf/
#
# 		Source related files.
#
SOURCEDIR = $(ROOTDIR)source/
#
#		Python script directory
#
SCRIPTDIR = $(SOURCEDIR)scripts/
#
#
#
# *******************************************************************************************
#
#								Build Configuration
#
# *******************************************************************************************
#
#		Use zero page from here (uses about 12 bytes or so) 
#
ZEROPAGE = 22
#
#		Use non zero page from here. (uses 240 bytes)
#
STORAGE = A000
#
# Code built for this address (this is a ROM bank)
CODEADDR = C000

#
#		Run the assembler
#
#ASSEMBLER = 64tass -q -c -C $(MEMORYMAP) -Wall main.asm -L $(BUILDDIR)asm.lst -o $(BINFILE) 

ASSEMBLER = cl65 --asm-args -g -o $(BUILDDIR)/asm.bin -t cx16 -C $(CONFDIR)/x16asm-rom.cfg --mapfile $(BUILDDIR)/x16asm-rom.map -Ln $(BUILDDIR)/x16asm-rom.sym -l $(BUILDDIR)/x16asm-rom.lst main.asm

asm: prelim
	$(ASSEMBLER)

prelim:
	rm -f dump*.bin
	$(MAKE) -C $(SCRIPTDIR) build

# *******************************************************************************************
#
#				    Uncommenting .SILENT will shut the whole build up.
#
# *******************************************************************************************

ifndef VERBOSE
.SILENT:
endif

default: build 


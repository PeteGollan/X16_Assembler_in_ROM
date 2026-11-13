# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		Makefile
#		Purpose :	Basic testing of module.
#		Date :		11th March 2025
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

include ../../build_env/common.make
#
#		Run the test suite. Okay, maybe suite it a bit of an exaggeration.
#
test: prelim
	$(MAKE) opcodes
	echo "Opcodes test: successful"
	$(MAKE) data
	echo "Data Pseudo-Ops test: successful"
	$(MAKE) include
	echo "Include text and binary test: successful"
	$(MAKE) address
	echo "Address mode test: successful"
	$(MAKE) math
	echo "Arithmetic test: successful"
	$(MAKE) macros
	echo "Macro test: successful"
	
opcodes: 
	$(call check_assembler,opcodes)
data:
	$(call check_assembler,data)
include:
	$(call check_assembler,include)
address:
	$(call check_assembler,address)
math:
	$(call check_assembler,math)
macros:
	$(call check_assembler,macros)

#
#		Run the test on tests/[param1].asm ; compiles same source with this assembler
# 		and 64tass and compares the result.
#
define check_assembler	
	cp tests/$(1).asm code.asm
	$(ASSEMBLER) -D TESTING=3
	64tass --mw65c02 -q -b -o $(BUILDDIR)compare.bin -L $(BUILDDIR)compare.lst code.asm
	$(EMULATOR)
	$(PYTHON) compare.py $(BUILDDIR)compare.bin
	rm -f dump*.bin code.asm
endef	
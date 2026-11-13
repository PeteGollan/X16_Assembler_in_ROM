# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		Makefile
#		Purpose :	Basic testing of expressions
#		Date :		11th March 2025
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

include ../../build_env/common.make

#
#		Evaluation unit tests.
#
test: prelim
	$(PYTHON) expr.py >$(BUILDDIR)testdata.inc
	$(ASSEMBLER) -D TESTING=1
	$(EMULATOR)
	echo "Expression testing successful"
	rm -f dump.bin
#
#		This just sets up on evaluation for bug fixing.
#
testdebug: prelim
	$(PYTHON) setupexpr.py >$(BUILDDIR)testdata.inc
	$(ASSEMBLER) -D TESTING=1
	$(EMULATOR)
	rm -f dump.bin

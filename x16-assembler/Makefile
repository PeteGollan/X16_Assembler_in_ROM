# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		Makefile
#		Purpose :	Top level Makefile
#		Date :		11th March 2025
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

include build_env/common.make

.always:

#
#		Does a test build of the library module
#
build: .always
	$(MAKE) -B -C source build
#
#		Does a test run of the library module
#
run: .always
	$(MAKE) -B -C source run
#
#		Runs the scripts which generate files. If you get file not found errors might be this
#
scripts: .always
	$(MAKE) -B -C $(SCRIPTDIR) build
#
#		Run the tests
#
test: .always
	$(MAKE) -B -C testing test

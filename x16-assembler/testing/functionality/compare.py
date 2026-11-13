# *******************************************************************************************
# *******************************************************************************************
#
#       Name :      compare.py
#       Purpose :   Compare 64tass / x16-assembler outputs
#       Date :      11th March 2025
#       Author :    Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import sys

tass = [x for x in open(sys.argv[1],"rb").read(-1)]
dump = [x for x in open("dump.bin","rb").read(-1)]
count = 0

for i in range(0,len(tass)):
    if tass[i] != dump[0x8000+i]:
        print("At ${0:04x} 64tass:${1:02x} x16:{2:02x}".format(i+0x8000,tass[i],dump[0x8000+i]))
        count += 1

sys.exit(0 if count == 0 else 1)        
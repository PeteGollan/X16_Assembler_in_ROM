# *******************************************************************************************
# *******************************************************************************************
#
#       Name :      showident.py
#       Purpose :   Show the identifier table
#       Date :      11th March 2025
#       Author :    Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import os,sys,math,re

addr = int(sys.argv[1],16)  
mem = [x for x in open("dump.bin","rb").read(-1)]

while mem[addr] != 0:
    name = ""
    p = addr + 7
    while p != 0:
        name += chr(mem[p] & 0x7F)
        macro = p
        p = 0 if mem[p] >= 0x80 else p+1
    v = (mem[addr+5] << 8)+ mem[addr+4]     
    print("@{0:04x} {6:<15} H:${1:02x} T:${2:02x} F:${3:02x} D:${4:02x},${5:02x},${8:02x} : ${8:02x}:{7:04x} ({7})".
                            format(addr,mem[addr+1],mem[addr+2],mem[addr+3],mem[addr+4],mem[addr+5],name.lower().strip(),v,mem[addr+6]))

    if mem[addr+2] == 3:
        print("\t\t\t\t[")
        while mem[macro] != 0xFF:
            s = ""
            macro += 1
            while mem[macro] != 0x00:
                s = s + chr(mem[macro])
                macro += 1
            print("\t\t\t\t\t"+s.strip().lower())
            macro += 1
        print("\t\t\t\t]")
    addr += mem[addr]

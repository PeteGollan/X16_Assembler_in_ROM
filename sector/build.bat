@echo off
rem +------------------------------------------------------------------
rem | Build wsec.prg and rsec.prg (Write Sector and Read Sector)
rem |
rem | Asm programs that provides their own BASIC stub.
rem +------------------------------------------------------------------
rem
rem cl65 -t cx16 --cpu 65C02 -l sectorw.lst -o sectorw.prg sectorw.asm
cl65 -t cx16 -C cx16-asm.cfg --cpu 65C02 -l wsec.lst -o wsec.prg wsec.asm
cl65 -t cx16 -C cx16-asm.cfg --cpu 65C02 -l rsec.lst -o rsec.prg rsec.asm

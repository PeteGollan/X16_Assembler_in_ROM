@echo off
rem +------------------------------------------------------------------
rem | Build wsec.prg and rsec2.prg (Write Sector and Read Sector 2)
rem |
rem | Asm programs that provides their own BASIC stub.
rem +------------------------------------------------------------------
rem
rem cl65 -t cx16 --cpu 65C02 -l sectorw.lst -o sectorw.prg sectorw.asm
cl65 -t cx16 -C cx16-asm.cfg --cpu 65C02 -l wsec.lst -o wsec.prg wsec.asm
cl65 -t cx16 -C cx16-asm.cfg --cpu 65C02 -l rsec2.lst -o rsec2.prg rsec2.asm

# *******************************************************************************************
# *******************************************************************************************
#
#       Name :      makeasmtable816.py
#       Purpose :   Build the assembler information structure for 65C02/65C816.
#       Date :      11th March 2025
#       Author :    Paul Robson (paul@robsons.org.uk)
#   	Modified by Pete Wyspianski (AKA Gollan petegollan@outlook.com)
#       September 2026 for the X16-Assembler in ROM project
#
# *******************************************************************************************
# *******************************************************************************************

import os,sys,math,re

# *******************************************************************************************
#
#                                   Single mnemonic class
#
# *******************************************************************************************

class MnemonicBase(object):

    def __init__(self,group,mnemonic,opcode,flags,operand):
        self.group = group
        self.mnemonic = mnemonic
        self.opcode = opcode
        self.flags = flags

    def toString(self):
        return "{0:4} ${2:02x} Group:{1}".format(
            self.mnemonic,
            self.group,
            self.opcode
        )

    def getAuxData(self):
        return 0

    def getFlags(self):
        return self.flags

class Mnemonic(MnemonicBase):
    pass

class MnemonicGroup2(MnemonicBase):

    def __init__(self,group,mnemonic,opcode,flags,operand):

        MnemonicBase.__init__(
            self,
            group,
            mnemonic,
            opcode,
            flags,
            operand
        )

        #
        # Remove whitespace
        #
        bits = operand.strip().replace(" ","")

        #
        # Expect 24 selector bits
        #
        assert len(bits) == 24, \
            "Bad selector on " + MnemonicBase.toString(self)

        #
        # Convert X/- notation to binary
        #
        bits = bits.replace("-","0").replace("X","1")

        #
        # Store the three selector bytes
        #
        self.selector = (
            int(bits[0:8],2),
            int(bits[8:16],2),
            int(bits[16:24],2)
        )

        #
        # Filled in later by AssemblerDictionary
        #
        self.selectorIndex = 0

    def setSelectorIndex(self,index):
        self.selectorIndex = index

    def getSelector(self):
        return self.selector

    def toString(self):
        return (
            MnemonicBase.toString(self) +
            " Sel:{0:02X},{1:02X},{2:02X}".format(
                self.selector[0],
                self.selector[1],
                self.selector[2]
            )
        )

    def getAuxData(self):
        #
        # Dictionary stores selector-table index
        #
        return self.selectorIndex


# *******************************************************************************************
#
#                                   Assembler Dictionary Class
#
# *******************************************************************************************

class AssemblerDictionary(object):
    def __init__(self):
        self.objects = {}
        self.fixes = []
        self.g2Selectors = []
        self.load()

    def load(self):
        for s in open("opcodes/opcodes816.txt").readlines():

            s = s.strip().upper().replace("\t"," ")

            if not s.startswith(";") and s != "":

                m = re.match(
                    "^([0-9A-F]+)\\s+([0-9A-F]+)\\s+(\\w+)\\s+(\\d)\\s*(.*)$",
                    s
                )

                assert m is not None, "Bad entry '"+s+"'"

                opcode   = int(m.group(1),16)
                flags    = int(m.group(2),16)
                mnemonic = m.group(3)
                groupID  = int(m.group(4))
                operand  = m.group(5)

                #
                # Fixup records
                #
                if groupID == 5:

                    m2 = re.match(
                        "\\s*(\\*?)(\\d+)\\s*(.*)",
                        operand
                    )

                    assert m2 is not None, \
                        "Bad table "+operand

                    arec = self.objects[mnemonic]

                    newFix = [
                        mnemonic,
                        arec.opcode,
                        opcode,
                        int(m2.group(2),10) +
                            (128 if m2.group(1) == '*' else 0),
                        m2.group(3).strip()
                    ]

                    self.fixes.insert(0,newFix)

                #
                # Normal opcode records
                #
                else:

                    #
                    # Group 2
                    #
                    if groupID == 2:

                        mnm = MnemonicGroup2(
                            groupID,
                            mnemonic,
                            opcode,
                            flags,
                            operand.strip()
                        )

                        selector = mnm.getSelector()

                        try:
                            selectorIndex = \
                                self.g2Selectors.index(selector)

                        except ValueError:

                            selectorIndex = \
                                len(self.g2Selectors)

                            self.g2Selectors.append(selector)

                        mnm.setSelectorIndex(
                            selectorIndex
                        )

                    #
                    # All other groups
                    #
                    else:

                        mnm = Mnemonic(
                            groupID,
                            mnemonic,
                            opcode,
                            flags,
                            operand.strip()
                        )

                    assert mnemonic not in self.objects, \
                        "Duplicate "+s

                    self.objects[mnemonic] = mnm

    def dumpFixupTable(self):
         h = open("../assembler/generated/__fixups816.asm","w")
         h.write(";\n;\tThis file is automatically generated.\n;\nAXGroup2OpcodeFixupTable816:\n")
         for f in self.fixes:
             h.write("\t.byte\t${0:02x},{1},\t\t\t${2:02x} ; {3} {4}\n".format(f[1],f[3],f[2],f[0],f[4]))
         h.write("\t.byte\t0\n")
         h.close()
    def createDictionary(self):
         h = open("../assembler/generated/__dictionary816.asm","w")
         h.write(";\n;\tThis file is automatically generated.\n;\nAXSystemDictionary816:\n")
         for k in self.objects.keys():
             r = self.objects[k]
             nameBytes = [ord(x) for x in r.mnemonic.upper()]
             nameBytes[-1] |= 0x80
             h.write("\t.byte\t{0}\n".format(len(r.mnemonic)+7))                 # offset
             h.write("\t.byte\t${0:02x}\n".format(sum(nameBytes) & 0xFF))        # hash
             h.write("\t.byte\t4\n") # type.
             h.write(
                 "\t.byte\t${0:02x}\n".format(
                     r.getFlags()
                 )
             )
             h.write("\t.byte\t{0},${1:02x}\n".format(r.group,r.opcode))         # data low (group) high (base opcode)
             h.write("\t.byte\t${0:02x}\n".format(r.getAuxData()))               # data aux (select bits for group 2)
             h.write("\t.byte\t{0:24} ; {1}\n".format(",".join(["${0:02x}".format(x) for x in nameBytes]),r.mnemonic))
             h.write("\n")
         self.createPsuedoOperations(h)          
         h.write("\t.byte\t0\n")
         h.close()

    def createPsuedoOperations(self,h):
        for root,dirs,files in os.walk("../assembler"):            
            for f in [x for x in files if x.endswith(".asm")]:  
                for s in open(root+os.sep+f).readlines():
                    if s.find(";;") > 0 and s.find("{") > 0:        
                        m = re.match("^(.*?)\\:\\s*\\;\\;\\s*\\{(.*?)\\}",s)
                        assert m is not None,"Bad line "+s
                        name = m.group(2).upper()
                        nameBytes = [ord(x) for x in name.upper()]
                        nameBytes[-1] |= 0x80
                        h.write("\t.byte\t{0}\n".format(len(name)+7))                       # offset
                        h.write("\t.byte\t${0:02x}\n".format(sum(nameBytes) & 0xFF))        # hash
                        h.write("\t.byte\t2\n")                                             # type.
                        h.write("\t.byte\t0\n")                                             # flags
                        h.write("\t.word\t{0}\n".format(m.group(1)))                        # address
                        h.write("\t.byte\t0\n")                                             # data aux (select bits for group 2)
                        h.write("\t.byte\t{0:24} ; {1}\n".format(",".join(["${0:02x}".format(x) for x in nameBytes]),name))
                        h.write("\n")

    def dumpG2SelectorTable(self):

        h = open(
            "../assembler/generated/__g2selector816.asm",
            "w"
        )
    
        h.write(";\n")
        h.write(";\tThis file is automatically generated.\n")
        h.write(";\n")
        h.write("G2SelectorTable816:\n")
    
        for i,s in enumerate(self.g2Selectors):
        
            h.write(
                "\t.byte\t${0:02x},${1:02x},${2:02x}\t; {3}\n".format(
                    s[0],
                    s[1],
                    s[2],
                    i
                )
            )
    
        h.close()

ad = AssemblerDictionary()
ad.dumpFixupTable()
ad.dumpG2SelectorTable()
ad.createDictionary()
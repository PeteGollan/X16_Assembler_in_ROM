# *******************************************************************************************
# *******************************************************************************************
#
#       Name :      expr.py
#       Purpose :   Test generator evaluation
#       Date :      11th March 2025
#       Author :    Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import os,sys,math,re,random

def outputTest(expr,result):
    expr = expr.strip()
    print("\t.byte\t{0}".format(len(expr)+4))                               # offset, answer (2) NULL
    print("\t.text\t'{0}',0".format(expr))
    print("\t.word\t{0}\n".format(result & 0xFFFF))

def encode(n):
    if random.randint(0,4) == 0:
        return "${0:X}".format(n)
    if random.randint(0,4) == 0:
        return "%{0:b}".format(n)
    return str(n)

def getNumber():
    n = random.randint(0,0xFFFF)
    return [n,encode(n)]

def getShort():
    n = random.randint(0,35)
    return [n,encode(n)]

def sp():
    if random.randint(0,2) == 0:
        return " "*random.randint(1,3)
    return ""

def createExpression(level):
    if level == 0:                                                  # level 0 = single term.
        return str(random.randint(1,4))
    elements = []
    for i in range(0,random.randint(1,3)):                          # build a chain at this level.
        elements.append(createExpression(level-1))
        elements.append("+*"[random.randint(0,1)])
    expr = " ".join(elements[:-1])
    return "("+expr+")" 

random.seed()

size = 400

# *******************************************************************************************
#
#                               Binary operators
#
# *******************************************************************************************

operator = "+ - * / % & | ^ << >> = <> <".split()

for n in range(0,size):
    n1 = getNumber()
    n2 = getNumber()
    op = operator[random.randint(0,len(operator)-1)]
    isCompare = (op[0] == "=" or op[0] == "<" or op[0] == ">") and ((op+"X")[1] != op[0])
    if isCompare and random.randint(0,4) == 0:
        n2 = n1
    if op == ">>" or op == "<<":
        n2 = getShort()
    reject = False
    if op == "/" or op == "%":
        if n2[0] == 0:
            reject = True
        else:
            result = n1[0] % n2[0] if op == "%" else (n1[0] // n2[0])
    elif op == "=":
        result = n1[0] == n2[0]
    elif op == "<>":
        result = n1[0] != n2[0]
    else:
        result = eval("{0}{1}{2}".format(n1[0],op,n2[0]))
    if isCompare:
        result = 0xFFFF if result else 0
    if not reject:
        outputTest("{5}{0}{3}{1}{4}{2}{6}".format(n1[1],op,n2[1],sp(),sp(),sp(),sp()),result)

# *******************************************************************************************
#
#                               Unary operators
#
# *******************************************************************************************

for n in range(0,size):
    n1 = getNumber()
    outputTest("-{0}".format(n1[1]),-n1[0])
    outputTest(">{0}".format(n1[1]),n1[0] >> 8)
    outputTest("<{0}".format(n1[1]),n1[0] & 0xFF)

# *******************************************************************************************
#
#                                   Parenthesis
#
# *******************************************************************************************

random.seed(42)
for n in range(0,size >> 3):
    x = createExpression(random.randint(1,4))
    e = eval(x.strip())
    if e < 0x10000 and len(x) < 80:
        outputTest(x,e)

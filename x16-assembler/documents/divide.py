import random
#
#       Calculate Q/M unsigned 16 bits.
#
#       Q = R       (Left)
#       M = L       (Right)
#       A = <New>   (Temp)
#
def divide(q,m):
    a = 0                                               # zero A
    for i in range(0,16):                               # iterate 16 times.
        #
        #       Shift AQ to the left one place, losing the MSB.
        #
        a = (a << 1) & 0xFFFF                           # shift A left
        if (q & 0x8000) != 0:                           # carry out Q into A
            a |= 0x0001
        q = (q << 1) & 0xFFFF
        #
        #       if A >= M then A = A - M and set Q:0
        #
        if a >= m:
            a = a - m                                   # subtract
            q |= 0x0001                                 # often written as increment, we know Q:0 is 0 though.

    return q                                            # Q is result, M remainder.

random.seed()
for i in range(0,10000):
    n1 = random.randint(0,0xFFFF)
    n2 = random.randint(1,0xFFFF)
    rc = int(n1/n2)
    ra = divide(n1,n2)
    if rc != ra:
        print(n1,"/",n2,rc,ra)

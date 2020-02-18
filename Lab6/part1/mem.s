mvi   r0, 0x00
mvhi  r0, 0x20 // address of SW
mvi   r1, 0x00
mvhi  r1, 0x30 // address of LEDR

loop:
ld    r3, r0   // read SW values
st    r3, r1   // update LEDR to match SW values
j loop // in an infinite loop
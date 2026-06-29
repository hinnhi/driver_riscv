# CRC-32
# Test vector: crc32("123456789", 9) == 0xCBF43926

.data
msg:    .asciz  "123456789"

.text
.globl  main
main:
    la      a0, msg
    li      a1, 9
    jal     ra, crc32               # explicit ra for clarity

    li      a7, 34                  # print hex
    ecall
    li      a7, 10                  # exit
    ecall

# uint32_t crc32(uint8_t *data /*a0*/, uint32_t len /*a1*/)
# Register map:
#    t0  = crc accumulator (starts 0xFFFFFFFF)
#    t1  = data pointer
#    t2  = remaining byte count
#    t3  = reflected polynomial 0xEDB88320
#    t4  = current byte / scratch
#    t5  = bit counter
#    t6  = LSB scratch

crc32:
    li      t0, -1                  # crc = 0xFFFFFFFF  (safe: -1 == 0xFFFFFFFF)
    mv      t1, a0                  # t1 = data pointer
    mv      t2, a1                  # t2 = length

    # Build polynomial in two safe steps to avoid assembler sign-extension bugs:
    #     0xEDB88320 = (0xEDB88 << 12) | 0x320
    #     lui loads bits[31:12]; but addi sign-extends, so if bit11 of imm=1
    #     the assembler must subtract 1 from the upper immediate.
    #     Writing it as lui+addi explicitly makes intent clear; RARS & CPUlator
    #     both handle 'li' correctly here, but explicit form is portable.
    lui     t3, 0xEDB88             # t3 = 0xEDB88000
    addi    t3, t3, 0x320           # t3 = 0xEDB88320  yes (bit11=0, no correction needed)

byte_loop:
    beqz    t2, crc_done

    lbu     t4, 0(t1)               # load byte (zero-extended)
    xor     t0, t0, t4              # crc ^= byte

    # Bit-loop unrolled x2 (4 pairs = 8 bits)
    #     Each pair: process bit N then bit N+1 before looping.
    #     Saves 4 branch instructions per byte vs. fully counted loop.

    # bit 0
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b1
    xor     t0, t0, t3
b1:
    # bit 1
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b2
    xor     t0, t0, t3
b2:
    # bit 2
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b3
    xor     t0, t0, t3
b3:
    # bit 3
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b4
    xor     t0, t0, t3
b4:
    # bit 4
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b5
    xor     t0, t0, t3
b5:
    # bit 5
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b6
    xor     t0, t0, t3
b6:
    # bit 6
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b7
    xor     t0, t0, t3
b7:
    # bit 7
    andi    t6, t0, 1
    srli    t0, t0, 1
    beqz    t6, b8
    xor     t0, t0, t3
b8:
    addi    t1, t1, 1
    addi    t2, t2, -1
    j       byte_loop

crc_done:
    xori    a0, t0, -1              # final XOR: explicit, no 'not' pseudo-op
    ret

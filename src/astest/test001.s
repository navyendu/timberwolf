main:
        jal     x1, test_mul

label1: jal     x0, label1

test_slti:
        slti    x3, x0, -1
        slti    x3, x0, 1
        slti    x3, x0, 0
        addi    x2, x0, 1
        slti    x4, x2, 0
        slti    x4, x2, 2
        slti    x4, x2, 1
        addi    x2, x0, -1
        slti    x5, x2, -2
        slti    x5, x2, 0
        slti    x5, x2, -1
        jalr    x0, x1, 0

test_sltiu:
        sltiu   x3, x0, -1
        sltiu   x3, x0, 1
        sltiu   x3, x0, 0
        addi    x2, x0, -1
        sltiu   x4, x2, -2
        sltiu   x4, x2, 0
        sltiu   x4, x2, -1
        addi    x2, x0, -2
        sltiu   x5, x2, -2
        sltiu   x5, x2, 0
        sltiu   x5, x2, -1
        jalr    x0, x1, 0

test_xori:
        xori    x3, x0, 0x123
        addi    x2, x1, 0x123
        xori    x3, x2, 0
        xori    x3, x2, -1
        xori    x3, x2, 0x123
        jalr    x0, x1, 0

test_ori:
        ori     x3, x0, 0x123
        addi    x2, x1, 0x123
        ori     x3, x2, 0
        ori     x3, x2, -1
        ori     x3, x2, 0x123
        jalr    x0, x1, 0

test_andi:
        andi    x3, x0, 0x123
        addi    x2, x1, 0x123
        andi    x3, x2, 0
        andi    x3, x2, -1
        andi    x3, x2, 0x123
        jalr    x0, x1, 0

test_slli:
        slli    x3, x0, 0x12
        addi    x2, x1, 0x123
        slli    x3, x2, 0
        slli    x3, x2, 1
        slli    x3, x2, 2
        slli    x3, x2, 16
        slli    x3, x2, 31
        slli    x3, x2, 32
        jalr    x0, x1, 0

test_srli:
        srli    x3, x0, 0x12
        addi    x2, x0, -0x123
        srli    x3, x2, 0
        srli    x3, x2, 1
        srli    x3, x2, 2
        srli    x3, x2, 16
        srli    x3, x2, 31
        srli    x3, x2, 32
        jalr    x0, x1, 0

test_srai:
        srai    x3, x0, 0x12
        addi    x2, x0, -0x123
        srai    x3, x2, 0
        srai    x3, x2, 1
        srai    x3, x2, 2
        srai    x3, x2, 16
        srai    x3, x2, 31
        srai    x3, x2, 32
        jalr    x0, x1, 0

test_add_sub:
        add     x2, x1, x0
        sub     x2, x1, x0
        addi    x2, x0, 0x123
        addi    x3, x0, 0x0
        add     x4, x3, x2
        sub     x5, x3, x2
        addi    x3, x0, 1
        add     x4, x3, x2
        sub     x5, x3, x2
        addi    x3, x0, -1
        add     x4, x3, x2
        sub     x5, x3, x2
        jalr    x0, x1, 0

test_sll:
        sll     x4, x0, 0x12
        addi    x2, x0, 0x123
        addi    x3, x0, 0
        sll     x4, x2, x3
        addi    x3, x0, 1
        sll     x4, x2, x3
        addi    x3, x0, 2
        sll     x4, x2, x3
        addi    x3, x0, 16
        sll     x4, x2, x3
        addi    x3, x0, 31
        sll     x4, x2, x3
        addi    x3, x0, 32
        sll     x4, x2, x3
        jalr    x0, x1, 0

test_srl:
        srl     x4, x0, 0x12
        addi    x2, x0, -0x123
        addi    x3, x0, 0
        srl     x4, x2, x3
        addi    x3, x0, 1
        srl     x4, x2, x3
        addi    x3, x0, 2
        srl     x4, x2, x3
        addi    x3, x0, 16
        srl     x4, x2, x3
        addi    x3, x0, 31
        srl     x4, x2, x3
        addi    x3, x0, 32
        srl     x4, x2, x3
        jalr    x0, x1, 0

test_sra:
        sra     x4, x0, 0x12
        addi    x2, x0, -0x123
        addi    x3, x0, 0
        sra     x4, x2, x3
        addi    x3, x0, 1
        sra     x4, x2, x3
        addi    x3, x0, 2
        sra     x4, x2, x3
        addi    x3, x0, 16
        sra     x4, x2, x3
        addi    x3, x0, 31
        sra     x4, x2, x3
        addi    x3, x0, 32
        sra     x4, x2, x3
        jalr    x0, x1, 0

test_and_or_xor:
        slt     x4, x0, x0
        sltu    x5, x0, x0
        addi    x2, x0, 0x123
        addi    x3, x0, -0x122
        and     x4, x2, x3
        or      x4, x2, x3
        xor     x4, x2, x3
        jalr    x0, x1, 0

test_mul:
        addi    x2, x0, 0x12
        addi    x3, x0, 0x34
        div     x4, x2, x3
        #mul     x5, x2, x3
        and     x6, x4, x3
        jalr    x0, x1, 0

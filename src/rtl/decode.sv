module decode
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    type T_in = logic,
    type T_tube_valid = logic,
    type T_tube_op = logic,
    type T_out = logic
)(
    input  logic                    clk,
    input  logic                    rst,
    
    input  T_in                     in,
    
    output logic [NUM_HART-1:0]     csr_rd_hart_sel,
    output logic [11:0]             csr_rd_addr,
    input  logic [REG_WIDTH-1:0]    csr,
    
    output logic [NUM_HART-1:0]     reg_rd_hart_sel,
    output logic [4:0]              reg1_rd_addr,
    output logic [4:0]              reg2_rd_addr,
    input  logic [REG_WIDTH-1:0]    reg1,
    input  logic [REG_WIDTH-1:0]    reg2,
    
    output T_out                    out
);
    localparam bit EN_RV32 = REG_WIDTH >= 32;
    localparam bit EN_RV64 = REG_WIDTH >= 64;
    
    localparam int unsigned BYTES_PER_REG = REG_WIDTH / 8;
    
    logic [31:0] instr;
    
    logic [1:0] op0;
    logic [4:2] op1;
    logic [6:5] op2;
    logic [14:12] op3;
    logic [31:25] op7;
    
    logic rv_grp_load;
    logic rv_grp_loadfp;
    logic rv_grp_miscmem;
    logic rv_grp_opimm;
    logic rv_grp_auipc;
    logic rv_grp_opimm32;
    logic rv_grp_store;
    logic rv_grp_storefp;
    logic rv_grp_amo;
    logic rv_grp_op;
    logic rv_grp_lui;
    logic rv_grp_op32;
    logic rv_grp_madd;
    logic rv_grp_msub;
    logic rv_grp_nmsub;
    logic rv_grp_nmadd;
    logic rv_grp_opfp;
    logic rv_grp_branch;
    logic rv_grp_jalr;
    logic rv_grp_jal;
    logic rv_grp_system;
    
    logic [REG_WIDTH-1:0] imm_i;
    logic [REG_WIDTH-1:0] imm_s;
    logic [REG_WIDTH-1:0] imm_b;
    logic [REG_WIDTH-1:0] imm_u;
    logic [REG_WIDTH-1:0] imm_j;
    logic [REG_WIDTH-1:0] imm;
    
    logic [REG_WIDTH-1:0] lane_a;
    logic [REG_WIDTH-1:0] lane_b;
    logic [REG_WIDTH-1:0] lane_c;
    logic [REG_WIDTH-1:0] lane_d;
    
    logic lane_j_add_pc;
    T_tube_valid exec_tube_sel;
    T_tube_op exec_tube_op;
    
    logic collision;
    logic raw1_hazard;
    logic raw2_hazard;
    logic waw_hazard;
    logic hazard;
    logic issue;    // Big one
    
    logic pc_wr_en;
    
    logic mem_rd_en;
    logic mem_wr_en;
    logic [BYTES_PER_REG-1:0] mem_wr_ben;
    logic mem_lane_y_sel_j;
    logic mem_lane_y_sel_k;
    
    logic csr_wr_en;
    
    logic       reg_wr_en;
    logic [4:0] reg_wr_addr;
    
    always_comb instr = in.instr[31:0];
    
    always_comb op0 = instr[1:0];
    always_comb op1 = instr[4:2];
    always_comb op2 = instr[6:5];
    always_comb op3 = instr[14:12];
    always_comb op7 = instr[31:25];
    
    always_comb csr_rd_hart_sel = in.hart_sel;
    always_comb csr_rd_addr = instr[31:20];
    
    always_comb reg_rd_hart_sel = in.hart_sel;
    always_comb reg1_rd_addr = instr[19:15];
    always_comb reg2_rd_addr = instr[24:20];
    
    always_comb rv_grp_load    = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b000) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_loadfp  = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b001) & (op0 == 2'b11);
    always_comb rv_grp_miscmem = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b011) & (op0 == 2'b11);
    always_comb rv_grp_opimm   = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b100) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_auipc   = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b101) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_opimm32 = in.instr_valid & (op2 == 2'b00) & (op1 == 3'b110) & (op0 == 2'b11) & EN_RV64;
    always_comb rv_grp_store   = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b000) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_storefp = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b001) & (op0 == 2'b11);
    always_comb rv_grp_amo     = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b011) & (op0 == 2'b11);
    always_comb rv_grp_op      = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b100) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_lui     = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b101) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_op32    = in.instr_valid & (op2 == 2'b01) & (op1 == 3'b110) & (op0 == 2'b11) & EN_RV64;
    always_comb rv_grp_madd    = in.instr_valid & (op2 == 2'b10) & (op1 == 3'b000) & (op0 == 2'b11);
    always_comb rv_grp_msub    = in.instr_valid & (op2 == 2'b10) & (op1 == 3'b001) & (op0 == 2'b11);
    always_comb rv_grp_nmsub   = in.instr_valid & (op2 == 2'b10) & (op1 == 3'b000) & (op0 == 2'b11);
    always_comb rv_grp_nmadd   = in.instr_valid & (op2 == 2'b10) & (op1 == 3'b011) & (op0 == 2'b11);
    always_comb rv_grp_opfp    = in.instr_valid & (op2 == 2'b10) & (op1 == 3'b100) & (op0 == 2'b11);
    always_comb rv_grp_branch  = in.instr_valid & (op2 == 2'b11) & (op1 == 3'b000) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_jalr    = in.instr_valid & (op2 == 2'b11) & (op1 == 3'b001) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_jal     = in.instr_valid & (op2 == 2'b11) & (op1 == 3'b011) & (op0 == 2'b11) & EN_RV32;
    always_comb rv_grp_system  = in.instr_valid & (op2 == 2'b11) & (op1 == 3'b100) & (op0 == 2'b11) & EN_RV32;
    
    always_comb imm_i = { { REG_WIDTH-11 {instr[31]} }, instr[30:20] };
    always_comb imm_s = { { REG_WIDTH-11 {instr[31]} }, instr[30:25], instr[11:8], instr[7] };
    always_comb imm_b = { { REG_WIDTH-12 {instr[31]} }, instr[7], instr[30:25], instr[11:8], 1'b0 };
    always_comb imm_u = { { REG_WIDTH-31 {instr[31]} }, instr[30:12], 12'b0 };
    always_comb imm_j = { { REG_WIDTH-20 {instr[31]} }, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0 };
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        imm = imm_i;
            rv_grp_loadfp:      imm = 'x;
            rv_grp_miscmem:     imm = imm_i;
            rv_grp_opimm:       imm = imm_i;
            rv_grp_auipc:       imm = imm_u;
            rv_grp_opimm32:     imm = imm_i;
            rv_grp_store:       imm = imm_s;
            rv_grp_storefp:     imm = 'x;
            rv_grp_amo:         imm = 'x;
            rv_grp_op:          imm = 'x;
            rv_grp_lui:         imm = imm_u;
            rv_grp_op32:        imm = 'x;
            rv_grp_madd:        imm = 'x;
            rv_grp_msub:        imm = 'x;
            rv_grp_nmsub:       imm = 'x;
            rv_grp_nmadd:       imm = 'x;
            rv_grp_opfp:        imm = 'x;
            rv_grp_branch:      imm = imm_b;
            rv_grp_jalr:        imm = imm_i;
            rv_grp_jal:         imm = imm_j;
            rv_grp_system:      imm = 'x;
            default:            imm = 'x;
        endcase
    end
    
    always_comb lane_a = in.pc;
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        lane_b = imm;
            rv_grp_loadfp:      lane_b = 'x;
            rv_grp_miscmem:     lane_b = 'x;
            rv_grp_opimm:       lane_b = 'x;
            rv_grp_auipc:       lane_b = imm;
            rv_grp_opimm32:     lane_b = 'x;
            rv_grp_store:       lane_b = reg2;
            rv_grp_storefp:     lane_b = 'x;
            rv_grp_amo:         lane_b = 'x;
            rv_grp_op:          lane_b = 'x;
            rv_grp_lui:         lane_b = imm;
            rv_grp_op32:        lane_b = 'x;
            rv_grp_madd:        lane_b = 'x;
            rv_grp_msub:        lane_b = 'x;
            rv_grp_nmsub:       lane_b = 'x;
            rv_grp_nmadd:       lane_b = 'x;
            rv_grp_opfp:        lane_b = 'x;
            rv_grp_branch:      lane_b = imm;
            rv_grp_jalr:        lane_b = imm;
            rv_grp_jal:         lane_b = imm;
            rv_grp_system:      lane_b = csr;
            default:            lane_b = 'x;
        endcase
    end
    always_comb lane_c = reg1;
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        lane_d = imm;
            rv_grp_loadfp:      lane_d = 'x;
            rv_grp_miscmem:     lane_d = 'x;
            rv_grp_opimm:       lane_d = imm;
            rv_grp_auipc:       lane_d = '0;
            rv_grp_opimm32:     lane_d = imm;
            rv_grp_store:       lane_d = imm;
            rv_grp_storefp:     lane_d = 'x;
            rv_grp_amo:         lane_d = 'x;
            rv_grp_op:          lane_d = reg2;
            rv_grp_lui:         lane_d = '0;
            rv_grp_op32:        lane_d = reg2;
            rv_grp_madd:        lane_d = 'x;
            rv_grp_msub:        lane_d = 'x;
            rv_grp_nmsub:       lane_d = 'x;
            rv_grp_nmadd:       lane_d = 'x;
            rv_grp_opfp:        lane_d = 'x;
            rv_grp_branch:      lane_d = reg2;
            rv_grp_jalr:        lane_d = imm;
            rv_grp_jal:         lane_d = '0;
            rv_grp_system:      lane_d = csr;
            default:            lane_d = 'x;
        endcase
    end
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_loadfp:      exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_miscmem:     exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_opimm:       exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_auipc:       exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_opimm32:     exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_store:       exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_storefp:     exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_amo:         exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_op: begin
                unique if (op7 == 7'b0000001) begin
                    unique case (op3[14])
                        1'b1:   exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b1 };
                        default:exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b1, tube_8c: 1'b0 };
                    endcase
                end else begin
                                exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
                end
            end
            rv_grp_lui:         exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_op32:        exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_madd:        exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_msub:        exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_nmsub:       exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_nmadd:       exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_opfp:        exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_branch:      exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_jalr:        exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_jal:         exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
            rv_grp_system:      exec_tube_sel = '{ tube_0c: 1'b1, tube_4c: 1'b0, tube_8c: 1'b0 };
            default:            exec_tube_sel = '{ tube_0c: 1'b0, tube_4c: 1'b0, tube_8c: 1'b0 };
        endcase
    end
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'b0, rsel: 2'b00, fsel: 2'b00 };
            rv_grp_loadfp:      exec_tube_op.tube_0c = 'z;
            rv_grp_miscmem:     exec_tube_op.tube_0c = 'z;
            rv_grp_opimm: begin
                unique case (op3)
                    3'b000:     exec_tube_op.tube_0c = '{ sign: 1'b1,    inv2: 1'b0, cin: 1'b0, rsel: 2'bxx, fsel: 2'b00 }; // ADDI
                    3'b001:     exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'bx, rsel: 2'b00, fsel: 2'b11 }; // SLLI
                    3'b010:     exec_tube_op.tube_0c = '{ sign: 1'b1,    inv2: 1'b1, cin: 1'b1, rsel: 2'b10, fsel: 2'b01 }; // SLTI
                    3'b011:     exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b1, cin: 1'b1, rsel: 2'b10, fsel: 2'b01 }; // SLTIU
                    3'b100:     exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'bx, rsel: 2'b00, fsel: 2'b10 }; // XORI
                    3'b101:     exec_tube_op.tube_0c = '{ sign: op7[30], inv2: 1'b0, cin: 1'bx, rsel: 2'b10, fsel: 2'b11 }; // SRLI/SRAI
                    3'b110:     exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'bx, rsel: 2'b10, fsel: 2'b10 }; // ORI
                    3'b111:     exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'bx, rsel: 2'b11, fsel: 2'b10 }; // ANDI
                    default:    exec_tube_op.tube_0c = 'x;
                endcase
            end
            rv_grp_auipc:       exec_tube_op.tube_0c = 'x;
            rv_grp_opimm32:     exec_tube_op.tube_0c = 'z;
            rv_grp_store:       exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0, cin: 1'b0, rsel: 2'bxx, fsel: 2'b00 };
            rv_grp_storefp:     exec_tube_op.tube_0c = 'z;
            rv_grp_amo:         exec_tube_op.tube_0c = 'z;
            rv_grp_op: begin
                unique if (op7 == 7'b0000001) begin
                    unique case (op3)
                        3'b000: exec_tube_op.tube_4c = '{ rsvd: '0 }; 
                        3'b001: exec_tube_op.tube_4c = '{ rsvd: '0 }; 
                        3'b010: exec_tube_op.tube_4c = '{ rsvd: '0 }; 
                        3'b011: exec_tube_op.tube_4c = '{ rsvd: '0 }; 
                        3'b100: exec_tube_op.tube_8c = '{ rsvd: '0 }; 
                        3'b101: exec_tube_op.tube_8c = '{ rsvd: '0 }; 
                        3'b110: exec_tube_op.tube_8c = '{ rsvd: '0 }; 
                        3'b111: exec_tube_op.tube_8c = '{ rsvd: '0 }; 
                        default:exec_tube_op.tube_4c = 'x;
                    endcase
                end else begin
                    unique case (op3)
                        3'b000: exec_tube_op.tube_0c = '{ sign: 1'b1,    inv2: op7[30], cin: op7[30], rsel: 2'bxx, fsel: 2'b00 }; // ADD/SUB
                        3'b001: exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0,    cin: 1'bx,    rsel: 2'b00, fsel: 2'b11 }; // SLL
                        3'b010: exec_tube_op.tube_0c = '{ sign: 1'b1,    inv2: 1'b1,    cin: 1'b1,    rsel: 2'b10, fsel: 2'b01 }; // SLT
                        3'b011: exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b1,    cin: 1'b1,    rsel: 2'b10, fsel: 2'b01 }; // SLTU
                        3'b100: exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0,    cin: 1'bx,    rsel: 2'b00, fsel: 2'b10 }; // XOR
                        3'b101: exec_tube_op.tube_0c = '{ sign: op7[30], inv2: 1'b0,    cin: 1'bx,    rsel: 2'b10, fsel: 2'b11 }; // SRL/SRA
                        3'b110: exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0,    cin: 1'bx,    rsel: 2'b10, fsel: 2'b10 }; // OR
                        3'b111: exec_tube_op.tube_0c = '{ sign: 1'b0,    inv2: 1'b0,    cin: 1'bx,    rsel: 2'b11, fsel: 2'b10 }; // AND
                        default:exec_tube_op.tube_0c = 'x;
                    endcase
                end
            end
            rv_grp_lui:         exec_tube_op.tube_0c = 'x;
            rv_grp_op32:        exec_tube_op.tube_0c = 'z;
            rv_grp_madd:        exec_tube_op.tube_0c = 'z;
            rv_grp_msub:        exec_tube_op.tube_0c = 'z;
            rv_grp_nmsub:       exec_tube_op.tube_0c = 'z;
            rv_grp_nmadd:       exec_tube_op.tube_0c = 'z;
            rv_grp_opfp:        exec_tube_op.tube_0c = 'z;
            rv_grp_branch: begin
                unique case (op3)
                    3'b000:     exec_tube_op.tube_0c = '{ sign: 1'bx, inv2: 1'b1, cin: 1'bx, rsel: 2'b00, fsel: 2'b01 }; // BEQ
                    3'b001:     exec_tube_op.tube_0c = '{ sign: 1'bx, inv2: 1'b1, cin: 1'bx, rsel: 2'b01, fsel: 2'b01 }; // BNE
                    3'b100:     exec_tube_op.tube_0c = '{ sign: 1'b1, inv2: 1'b1, cin: 1'b0, rsel: 2'b10, fsel: 2'b01 }; // BLT
                    3'b101:     exec_tube_op.tube_0c = '{ sign: 1'b1, inv2: 1'b1, cin: 1'b0, rsel: 2'b11, fsel: 2'b01 }; // BGE
                    3'b110:     exec_tube_op.tube_0c = '{ sign: 1'b0, inv2: 1'b1, cin: 1'b0, rsel: 2'b10, fsel: 2'b01 }; // BLTU
                    3'b111:     exec_tube_op.tube_0c = '{ sign: 1'b0, inv2: 1'b1, cin: 1'b0, rsel: 2'b11, fsel: 2'b01 }; // BGEU
                    default:    exec_tube_op.tube_0c = 'x;
                endcase
            end
            rv_grp_jalr:        exec_tube_op.tube_0c = '{ sign: 1'b0, inv2: 1'b0, cin: 1'b0, rsel: 2'bxx, fsel: 2'b00 };
            rv_grp_jal:         exec_tube_op.tube_0c = 'x;
            rv_grp_system:      exec_tube_op.tube_0c = 'z;
            default:            exec_tube_op.tube_0c = 'x;
        endcase
    end
    
    if (1) begin: gen_collision_matrix
        typedef struct packed {
            logic       valid;
            logic [4:0] reg_wr_addr;
        } tracker_type;
        
        tracker_type tube4c_in;
        tracker_type tube8c_in;
        
        tracker_type tube4c_vec [4];
        tracker_type tube8c_vec [8];
        
        always_comb tube4c_in = '{
            valid: exec_tube_sel.tube_4c, reg_wr_addr: reg_wr_addr
        };
        tube_tracker #(4, tracker_type) i_tube_tracker_4c (
            .clk    (clk),
            .rst    (rst),
            .in     (tube4c_in),
            .vec    (tube4c_vec)
        );
        
        always_comb tube8c_in = '{
            valid: exec_tube_sel.tube_8c, reg_wr_addr: reg_wr_addr
        };
        tube_tracker #(8, tracker_type) i_tube_tracker_8c (
            .clk    (clk),
            .rst    (rst),
            .in     (tube8c_in),
            .vec    (tube8c_vec)
        );
        
        always_comb collision =
            (exec_tube_sel.tube_0c & (tube4c_vec[0].valid | tube8c_vec[0].valid)) |
            (exec_tube_sel.tube_4c & (tube8c_vec[4].valid));
        
        // It's implied that usage of tube4c or tube8c is followed by a reg write
        always_comb raw1_hazard =
            // Current instr is 0c, 8c in tube
            (exec_tube_sel.tube_0c & (tube8c_vec[4].valid & (tube8c_vec[4].reg_wr_addr == reg1_rd_addr)));
        always_comb raw2_hazard =
            // Current instr is 0c, 8c in tube
            (exec_tube_sel.tube_0c & (tube8c_vec[4].valid & (tube8c_vec[4].reg_wr_addr == reg2_rd_addr)));
        always_comb waw_hazard =
            // Current instr is 0c, 8c in tube
            (exec_tube_sel.tube_0c & (tube8c_vec[4].valid & (tube8c_vec[4].reg_wr_addr == reg_wr_addr)));
        
        always_comb hazard = raw1_hazard | raw2_hazard | waw_hazard;
    end: gen_collision_matrix
    
    // Issue pc only if 32-bit instruction
    always_comb issue = in.instr_valid & (op1 != 3'b111) & (op0 == 2'b11) &
        ~collision & ~hazard;
    
    always_comb pc_wr_en = issue;
    
    always_comb mem_rd_en = issue & rv_grp_load;
    always_comb mem_wr_en = issue & rv_grp_store;
    always_comb begin
        unique case (1'b1)
            rv_grp_store: begin
                mem_wr_ben = '0;
                
                unique case (op3)
                    3'b000:     mem_wr_ben[0]   = 1'b1;
                    3'b001:     mem_wr_ben[1:0] = 2'b11;
                    3'b010:     mem_wr_ben[3:0] = 4'b1111;
                    3'b011:     mem_wr_ben      = '1;
                    default:    mem_wr_ben      = 'x;
                endcase
            end
            default:            mem_wr_ben      = 'x;
        endcase
    end
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        lane_j_add_pc = 1'b0;
            rv_grp_loadfp:      lane_j_add_pc = 1'b0;
            rv_grp_miscmem:     lane_j_add_pc = 1'b0;
            rv_grp_opimm:       lane_j_add_pc = 1'b0;
            rv_grp_auipc:       lane_j_add_pc = 1'b1;
            rv_grp_opimm32:     lane_j_add_pc = 1'b0;
            rv_grp_store:       lane_j_add_pc = 1'b0;
            rv_grp_storefp:     lane_j_add_pc = 1'b0;
            rv_grp_amo:         lane_j_add_pc = 1'b0;
            rv_grp_op:          lane_j_add_pc = 1'b0;
            rv_grp_lui:         lane_j_add_pc = 1'b0;
            rv_grp_op32:        lane_j_add_pc = 1'b0;
            rv_grp_madd:        lane_j_add_pc = 1'b0;
            rv_grp_msub:        lane_j_add_pc = 1'b0;
            rv_grp_nmsub:       lane_j_add_pc = 1'b0;
            rv_grp_nmadd:       lane_j_add_pc = 1'b0;
            rv_grp_opfp:        lane_j_add_pc = 1'b0;
            rv_grp_branch:      lane_j_add_pc = 1'b1;
            rv_grp_jalr:        lane_j_add_pc = 1'b0;
            rv_grp_jal:         lane_j_add_pc = 1'b1;
            rv_grp_system:      lane_j_add_pc = 1'b0;
            default:            lane_j_add_pc = 1'bx;
        endcase
    end
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        mem_lane_y_sel_j = 1'b0;
            rv_grp_loadfp:      mem_lane_y_sel_j = 1'b0;
            rv_grp_miscmem:     mem_lane_y_sel_j = 1'b0;
            rv_grp_opimm:       mem_lane_y_sel_j = 1'b0;
            rv_grp_auipc:       mem_lane_y_sel_j = 1'b1;
            rv_grp_opimm32:     mem_lane_y_sel_j = 1'b0;
            rv_grp_store:       mem_lane_y_sel_j = 1'b0;
            rv_grp_storefp:     mem_lane_y_sel_j = 1'b0;
            rv_grp_amo:         mem_lane_y_sel_j = 1'b0;
            rv_grp_op:          mem_lane_y_sel_j = 1'b0;
            rv_grp_lui:         mem_lane_y_sel_j = 1'b1;
            rv_grp_op32:        mem_lane_y_sel_j = 1'b0;
            rv_grp_madd:        mem_lane_y_sel_j = 1'b0;
            rv_grp_msub:        mem_lane_y_sel_j = 1'b0;
            rv_grp_nmsub:       mem_lane_y_sel_j = 1'b0;
            rv_grp_nmadd:       mem_lane_y_sel_j = 1'b0;
            rv_grp_opfp:        mem_lane_y_sel_j = 1'b0;
            rv_grp_branch:      mem_lane_y_sel_j = 1'b0;
            rv_grp_jalr:        mem_lane_y_sel_j = 1'b0;
            rv_grp_jal:         mem_lane_y_sel_j = 1'b0;
            rv_grp_system:      mem_lane_y_sel_j = 1'b0;
            default:            mem_lane_y_sel_j = 1'bx;
        endcase
    end
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        mem_lane_y_sel_k = 1'b0;
            rv_grp_loadfp:      mem_lane_y_sel_k = 1'b0;
            rv_grp_miscmem:     mem_lane_y_sel_k = 1'b0;
            rv_grp_opimm:       mem_lane_y_sel_k = 1'b1;
            rv_grp_auipc:       mem_lane_y_sel_k = 1'b0;
            rv_grp_opimm32:     mem_lane_y_sel_k = 1'b1;
            rv_grp_store:       mem_lane_y_sel_k = 1'b0;
            rv_grp_storefp:     mem_lane_y_sel_k = 1'b0;
            rv_grp_amo:         mem_lane_y_sel_k = 1'b0;
            rv_grp_op:          mem_lane_y_sel_k = 1'b1;
            rv_grp_lui:         mem_lane_y_sel_k = 1'b0;
            rv_grp_op32:        mem_lane_y_sel_k = 1'b1;
            rv_grp_madd:        mem_lane_y_sel_k = 1'b0;
            rv_grp_msub:        mem_lane_y_sel_k = 1'b0;
            rv_grp_nmsub:       mem_lane_y_sel_k = 1'b0;
            rv_grp_nmadd:       mem_lane_y_sel_k = 1'b0;
            rv_grp_opfp:        mem_lane_y_sel_k = 1'b0;
            rv_grp_branch:      mem_lane_y_sel_k = 1'b0;
            rv_grp_jalr:        mem_lane_y_sel_k = 1'b0;
            rv_grp_jal:         mem_lane_y_sel_k = 1'b0;
            rv_grp_system:      mem_lane_y_sel_k = 1'b0;
            default:            mem_lane_y_sel_k = 1'bx;
        endcase
    end
    
    always_comb csr_wr_en = issue & 1'b0;
    
    always_comb begin
        unique case (1'b1)
            rv_grp_load:        reg_wr_en = issue & 1'b1;
            rv_grp_loadfp:      reg_wr_en = issue & 1'bz;
            rv_grp_miscmem:     reg_wr_en = issue & 1'bz;
            rv_grp_opimm:       reg_wr_en = issue & 1'b1;
            rv_grp_auipc:       reg_wr_en = issue & 1'b1;
            rv_grp_opimm32:     reg_wr_en = issue & 1'b1;
            rv_grp_store:       reg_wr_en = issue & 1'b0;
            rv_grp_storefp:     reg_wr_en = issue & 1'bz;
            rv_grp_amo:         reg_wr_en = issue & 1'bz;
            rv_grp_op:          reg_wr_en = issue & 1'b1;
            rv_grp_lui:         reg_wr_en = issue & 1'b1;
            rv_grp_op32:        reg_wr_en = issue & 1'b1;
            rv_grp_madd:        reg_wr_en = issue & 1'bz;
            rv_grp_msub:        reg_wr_en = issue & 1'bz;
            rv_grp_nmsub:       reg_wr_en = issue & 1'bz;
            rv_grp_nmadd:       reg_wr_en = issue & 1'bz;
            rv_grp_opfp:        reg_wr_en = issue & 1'bz;
            rv_grp_branch:      reg_wr_en = issue & 1'b0;
            rv_grp_jalr:        reg_wr_en = issue & 1'b1;
            rv_grp_jal:         reg_wr_en = issue & 1'b1;
            rv_grp_system:      reg_wr_en = issue & 1'b1;
            default:            reg_wr_en = issue & 1'bx;
        endcase
    end
    always_comb reg_wr_addr = instr[11:7];
    
    always_comb out = '{
        hart_sel:           in.hart_sel,
        exec_tube_sel:      issue ? exec_tube_sel : '0,
        exec_tube_op:       exec_tube_op,
        pc_wr_en:           pc_wr_en,
        branch:             rv_grp_branch,
        pc_sel_j:           rv_grp_jal,
        pc_sel_k:           rv_grp_jalr,
        lane_y_sel_j:       mem_lane_y_sel_j,
        lane_y_sel_k:       mem_lane_y_sel_k,
        lane_j_add_pc:      lane_j_add_pc,
        mem_rd_en:          mem_rd_en,
        mem_wr_en:          mem_wr_en,
        mem_wr_ben:         mem_wr_ben,
        csr_wr_en:          csr_wr_en,
        csr_wr_addr:        instr[31:20],
        reg_wr_en:          reg_wr_en,
        reg_wr_size:        instr[13:12],
        reg_wr_sign_ext:    ~instr[14],
        reg_wr_addr:        reg_wr_addr,
        lane_a:             lane_a,
        lane_b:             lane_b,
        lane_c:             lane_c,
        lane_d:             lane_d
    };
endmodule

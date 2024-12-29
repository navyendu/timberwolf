module checker_core
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    int unsigned MEM_ADDR_WIDTH = 12
)(
    input logic     clk,
    input logic     rst
);
    localparam int unsigned BYTES_PER_REG = REG_WIDTH / 8;
    localparam int unsigned REG_BYTE_ADDR_BITS = $clog2(BYTES_PER_REG);
    localparam logic [MEM_ADDR_WIDTH-1:0] MEM_ADDR_BITMASK = ~((1 << REG_BYTE_ADDR_BITS) - 1);
    localparam int unsigned SHAMT_WIDTH = $clog2(REG_WIDTH);
    
    logic [NUM_HART-1:0]        hart_sel;
    logic [REG_WIDTH-1:0]       pc;
    logic                       instr_valid;
    logic [31:0]                instr;
    
    logic [NUM_HART-1:0]        pc_wr_hart_sel;
    logic                       pc_wr_en;
    logic [REG_WIDTH-1:0]       pc_wr_data;
    
    logic [MEM_ADDR_WIDTH-1:0]  dmem_addr;
    logic                       dmem_rd_en;
    logic                       dmem_wr_en;
    logic [REG_WIDTH-1:0]       dmem_wr_data;
    logic [BYTES_PER_REG-1:0]   dmem_wr_ben;
    
    logic [NUM_HART-1:0]        csr_wr_hart_sel;
    logic                       csr_wr_en;
    logic [11:0]                csr_wr_addr;
    logic [REG_WIDTH-1:0]       csr_wr_data;
    
    logic [NUM_HART-1:0]        reg_wr_hart_sel;
    logic                       reg_wr_en;
    logic [4:0]                 reg_wr_addr;
    logic [REG_WIDTH-1:0]       reg_wr_data;
    
    typedef struct packed {
        logic [NUM_HART-1:0]        mem_hart_id;
        logic                       mem_rden;
        logic                       mem_wren;
        logic [MEM_ADDR_WIDTH-1:0]  mem_addr;
        logic [REG_WIDTH-1:0]       mem_wrdata;
        logic [BYTES_PER_REG-1:0]   mem_wrben;
    } mem_type;
    
    typedef enum {
        LOAD,
        LOADFP,
        MISCMEM,
        OPIMM,
        AUIPC,
        OPIMM32,
        STORE,
        STOREFP,
        AMO,
        OP,
        LUI,
        OP32,
        MADD,
        MSUB,
        NMSUB,
        NMADD,
        OPFP,
        BRANCH,
        JALR,
        JAL,
        SYSTEM,
        ILLEGAL
    } instr_type;
    
    function automatic int unsigned onehot_to_bin(int unsigned a);
        int unsigned ret;
        
        ret = 0;
        
        for (int unsigned i = 0 ; (i < $bits(a)) && (a[0] != 1) ; i++) begin
            a = a >> 1;
            ret++;
        end
        
        return ret;
    endfunction
    
    function automatic instr_type instr_to_enum(logic [31:0] instr);
        logic [1:0] op0;
        logic [2:0] op1;
        logic [1:0] op2;
        
        op0 = instr[1:0];
        op1 = instr[4:2];
        op2 = instr[6:5];
        
        unique if ((op2 == 2'b00) & (op1 == 3'b000) & (op0 == 2'b11)) begin
            return LOAD;
        end else if ((op2 == 2'b00) & (op1 == 3'b001) & (op0 == 2'b11)) begin
            return LOADFP;
        end else if ((op2 == 2'b00) & (op1 == 3'b011) & (op0 == 2'b11)) begin
            return MISCMEM;
        end else if ((op2 == 2'b00) & (op1 == 3'b100) & (op0 == 2'b11)) begin
            return OPIMM;
        end else if ((op2 == 2'b00) & (op1 == 3'b101) & (op0 == 2'b11)) begin
            return AUIPC;
        end else if ((op2 == 2'b00) & (op1 == 3'b110) & (op0 == 2'b11)) begin
            return OPIMM32;
        end else if ((op2 == 2'b01) & (op1 == 3'b000) & (op0 == 2'b11)) begin
            return STORE;
        end else if ((op2 == 2'b01) & (op1 == 3'b001) & (op0 == 2'b11)) begin
            return STOREFP;
        end else if ((op2 == 2'b01) & (op1 == 3'b011) & (op0 == 2'b11)) begin
            return AMO;
        end else if ((op2 == 2'b01) & (op1 == 3'b100) & (op0 == 2'b11)) begin
            return OP;
        end else if ((op2 == 2'b01) & (op1 == 3'b101) & (op0 == 2'b11)) begin
            return LUI;
        end else if ((op2 == 2'b01) & (op1 == 3'b110) & (op0 == 2'b11)) begin
            return OP32;
        end else if ((op2 == 2'b10) & (op1 == 3'b000) & (op0 == 2'b11)) begin
            return MADD;
        end else if ((op2 == 2'b10) & (op1 == 3'b001) & (op0 == 2'b11)) begin
            return MSUB;
        end else if ((op2 == 2'b10) & (op1 == 3'b010) & (op0 == 2'b11)) begin
            return NMSUB;
        end else if ((op2 == 2'b10) & (op1 == 3'b011) & (op0 == 2'b11)) begin
            return NMADD;
        end else if ((op2 == 2'b10) & (op1 == 3'b100) & (op0 == 2'b11)) begin
            return OPFP;
        end else if ((op2 == 2'b11) & (op1 == 3'b000) & (op0 == 2'b11)) begin
            return BRANCH;
        end else if ((op2 == 2'b11) & (op1 == 3'b001) & (op0 == 2'b11)) begin
            return JALR;
        end else if ((op2 == 2'b11) & (op1 == 3'b011) & (op0 == 2'b11)) begin
            return JAL;
        end else if ((op2 == 2'b11) & (op1 == 3'b100) & (op0 == 2'b11)) begin
            return SYSTEM;
        end else begin
            return ILLEGAL;
        end
    endfunction
    
    always_comb hart_sel = core.i_pipeline.fetch_decode_pipe.hart_sel;
    always_comb instr_valid = core.i_pipeline.fetch_decode_pipe.instr_valid;
    always_comb pc = core.i_pipeline.fetch_decode_pipe.pc;
    always_comb instr = core.i_pipeline.fetch_decode_pipe.instr;
    
    always_comb pc_wr_hart_sel = core.pc_wr_hart_sel;
    always_comb pc_wr_en = core.pc_wr_en;
    always_comb pc_wr_data = core.pc_wr_data;
    
    always_comb dmem_addr = core.dmem_addr;
    always_comb dmem_rd_en = core.dmem_rd_en;
    always_comb dmem_wr_en = core.dmem_wr_en;
    always_comb dmem_wr_data = core.dmem_wr_data;
    always_comb dmem_wr_ben = core.dmem_wr_ben;
    
    always_comb csr_wr_hart_sel = core.csr_wr_hart_sel;
    always_comb csr_wr_en = core.csr_wr_en;
    always_comb csr_wr_addr = core.csr_wr_addr;
    always_comb csr_wr_data = core.csr_wr_data;
    
    always_comb reg_wr_hart_sel = core.reg_wr_hart_sel;
    always_comb reg_wr_en = core.reg_wr_en;
    always_comb reg_wr_addr = core.reg_wr_addr;
    always_comb reg_wr_data = core.reg_wr_data;
    
    mailbox#(mem_type) mbox_exp_mem;
    
    initial mbox_exp_mem = new();
    
    always @(posedge clk iff (rst & (dmem_rd_en | dmem_wr_en))) begin
        mem_type xmem;
        int unsigned reg_width_bytes;
        
        mbox_exp_mem.get(xmem);
        
        assert (xmem.mem_rden === dmem_rd_en) else begin
            $error("hart[%0d]: dmem_rd_en: expected 0b%0b, actual 0b%0b",
                onehot_to_bin(pc_wr_hart_sel), xmem.mem_rden, dmem_rd_en);
        end
        
        assert (xmem.mem_wren === dmem_wr_en) else begin
            $error("hart[%0d]: dmem_wr_en: expected 0b%0b, actual 0b%0b",
                onehot_to_bin(pc_wr_hart_sel), xmem.mem_wren, dmem_wr_en);
        end
        
        assert ((xmem.mem_addr & MEM_ADDR_BITMASK) === dmem_addr) else begin
            $error("hart[%0d]: dmem_addr: expected 0x%0h, actual 0x%0h",
                onehot_to_bin(pc_wr_hart_sel), xmem.mem_addr, dmem_addr);
        end
        
        if (dmem_wr_en) begin
            assert (xmem.mem_wrdata === dmem_wr_data) else begin
                $error("hart[%0d]: dmem_wr_data: expected 0x%0h, actual 0x%0h",
                    onehot_to_bin(pc_wr_hart_sel), xmem.mem_wrdata, dmem_wr_data);
            end
            
            assert (xmem.mem_wrben === dmem_wr_ben) else begin
                $error("hart[%0d]: dmem_wr_ben: expected 0b%0b, actual 0b%0b",
                    onehot_to_bin(pc_wr_hart_sel), xmem.mem_wrben, dmem_wr_ben);
            end
        end
    end
    
    for (genvar gi = 0 ; gi < NUM_HART ; gi++) begin: gen_hart
        logic [REG_WIDTH-1:0]   csr_list [4096];
        logic [REG_WIDTH-1:0]   gen_list [1:31];
        
        logic [REG_WIDTH-1:0]   exp_pc_next;
        logic                   exp_csr_wren;
        logic [11:0]            exp_csr_wraddr;
        logic [REG_WIDTH-1:0]   exp_csr_wrdata;
        logic                   exp_reg_wren;
        logic [REG_WIDTH-1:0]   exp_reg_wraddr;
        logic                   exp_reg_wrdata_valid;
        logic [REG_WIDTH-1:0]   exp_reg_wrdata;
        
        int fd_decode;
        int fd_mem_exp;
        int fd_mem_actual;
        
        initial begin
            fd_decode = $fopen($sformatf("decode.hart%0d.txt", gi), "w");
            if (!fd_decode) begin
                $fatal("Failed to open decode.hart%0d.txt", gi);
            end
        end
        
        final begin
            $fclose(fd_decode);
        end
        
        logic [REG_WIDTH-1:0] imm_tmp;
        logic [REG_WIDTH-1:0] rs1_tmp;
        logic [REG_WIDTH-1:0] exp_reg_wrdata_tmp;
        
        always @(negedge clk iff (rst & instr_valid & hart_sel[gi])) begin
            logic [1:0] op0;
            logic [2:0] op1;
            logic [1:0] op2;
            logic [2:0] op3;
            logic [6:0] op7;
            
            instr_type itype;
            
            logic [REG_WIDTH-1:0] imm_i;
            logic [REG_WIDTH-1:0] imm_s;
            logic [REG_WIDTH-1:0] imm_b;
            logic [REG_WIDTH-1:0] imm_u;
            logic [REG_WIDTH-1:0] imm_j;
            logic [REG_WIDTH-1:0] imm;
            
            logic [4:0] rd_addr;
            logic [4:0] rs1_addr;
            logic [4:0] rs2_addr;
            logic [11:0] csr_addr;
            
            logic [REG_WIDTH-1:0] rs1;
            logic [REG_WIDTH-1:0] rs2;
            logic [REG_WIDTH-1:0] csr;
            
            mem_type xmem;
            
            op0 = instr[1:0];
            op1 = instr[4:2];
            op2 = instr[6:5];
            op3 = instr[14:12];
            op7 = instr[31:25];
            
            itype = instr_to_enum(instr);
            
            imm_i = { { REG_WIDTH-11 {instr[31]} }, instr[30:20] };
            imm_s = { { REG_WIDTH-11 {instr[31]} }, instr[30:25], instr[11:8], instr[7] };
            imm_b = { { REG_WIDTH-12 {instr[31]} }, instr[7], instr[30:25], instr[11:8], 1'b0 };
            imm_u = { { REG_WIDTH-31 {instr[31]} }, instr[30:12], 12'b0 };
            imm_j = { { REG_WIDTH-20 {instr[31]} }, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0 };
            
            rd_addr = instr[11:7];
            rs1_addr = instr[19:15];
            rs2_addr = instr[24:20];
            csr_addr = instr[31:20];
            
            if (rs1_addr == '0) begin
                rs1 = '0;
            end else begin
                rs1 = core.i_reg_group.gen_reg_file[gi].i_reg_file.gen_reg.gen_list[rs1_addr];
            end
            
            if (rs2_addr == '0) begin
                rs2 = '0;
            end else begin
                rs2 = core.i_reg_group.gen_reg_file[gi].i_reg_file.gen_reg.gen_list[rs2_addr];
            end
            
            csr = csr_list[csr_addr];
            
            unique if (itype == LOAD) begin
                imm = imm_i;
                
                xmem = '{
                    mem_hart_id:    gi,
                    mem_rden:       1'b1,
                    mem_wren:       1'b0,
                    mem_addr:       rs1 + imm,
                    mem_wrdata:     'x,
                    mem_wrben:      'x
                };
                
                mbox_exp_mem.put(xmem);
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b0;
                exp_reg_wrdata = 'x;
            end else if (itype == LOADFP) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == MISCMEM) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == OPIMM) begin
                logic [REG_WIDTH-1:0] sra;
                
                imm = imm_i;
                
                imm_tmp = imm;
                rs1_tmp = rs1;
                sra = $signed(rs1) >>> imm[SHAMT_WIDTH-1:0];
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                unique case (op3)
                    3'b000: exp_reg_wrdata = rs1 + imm;
                    3'b001: exp_reg_wrdata = rs1 << imm[SHAMT_WIDTH-1:0];
                    3'b010: exp_reg_wrdata = $signed(rs1) < $signed(imm);
                    3'b011: exp_reg_wrdata = $unsigned(rs1) < $unsigned(imm);
                    3'b100: exp_reg_wrdata = rs1 ^ imm;
                    3'b101: exp_reg_wrdata = op7[5] ? sra
                                           : rs1 >> imm[SHAMT_WIDTH-1:0];
                    3'b110: exp_reg_wrdata = rs1 | imm;
                    3'b111: exp_reg_wrdata = rs1 & imm;
                endcase
            end else if (itype == AUIPC) begin
                imm = imm_u;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                exp_reg_wrdata = pc + imm;
            end else if (itype == OPIMM32) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                unique case (op3)
                    3'b000: exp_reg_wrdata = rs1 + imm;
                    3'b001: exp_reg_wrdata = rs1 << imm[4:0];
                    3'b010: exp_reg_wrdata = rs1 < imm;
                    3'b011: exp_reg_wrdata = rs1 < imm;
                    3'b100: exp_reg_wrdata = rs1 ^ imm;
                    3'b101: exp_reg_wrdata = imm[10] ? rs1 >>> imm[4:0]
                                           : rs1 >> imm[4:0];
                    3'b110: exp_reg_wrdata = rs1 | imm;
                    3'b111: exp_reg_wrdata = rs1 & imm;
                endcase
            end else if (itype == STORE) begin
                logic [MEM_ADDR_WIDTH-1:0] mem_addr;
                logic [BYTES_PER_REG-1:0] mem_wrben;
                
                imm = imm_s;
                mem_addr = rs1 + imm;
                
                case (op3)
                    3'b000: mem_wrben = 1'b1;
                    3'b001: mem_wrben = 2'b11;
                    3'b010: mem_wrben = 4'b1111;
                    3'b011: mem_wrben = 8'b11111111;
                    default: mem_wrben = 'x;
                endcase
                
                xmem = '{
                    mem_hart_id:    gi,
                    mem_rden:       1'b0,
                    mem_wren:       1'b1,
                    mem_addr:       mem_addr,
                    mem_wrdata:     rs2,
                    mem_wrben:      mem_wrben << mem_addr[REG_BYTE_ADDR_BITS-1:0]
                };
                
                mbox_exp_mem.put(xmem);
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b0;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == STOREFP) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b0;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == AMO) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == OP) begin
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                unique case (op3)
                    3'b000: begin
                        case (op7)
                            7'b0000000: exp_reg_wrdata = rs1 + rs2;
                            7'b0100000: exp_reg_wrdata = rs1 - rs2;
                            default:    exp_reg_wrdata = 'x;
                        endcase
                    end
                    3'b001: exp_reg_wrdata = 'x;
                    3'b010: exp_reg_wrdata = rs1 < rs2;
                    3'b011: exp_reg_wrdata = rs1 < rs2;
                    3'b100: exp_reg_wrdata = rs1 ^ rs2;
                    3'b101: exp_reg_wrdata = 'x;
                    3'b110: exp_reg_wrdata = rs1 | rs2;
                    3'b111: exp_reg_wrdata = rs1 & rs2;
                endcase
            end else if (itype == LUI) begin
                imm = imm_u;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                exp_reg_wrdata = imm;
            end else if (itype == OP32) begin
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                unique case (op3)
                    3'b000: begin
                        unique case (op7)
                            7'b0000000: exp_reg_wrdata = rs1 + rs2;
                            7'b0100000: exp_reg_wrdata = rs1 - rs2;
                            default:    exp_reg_wrdata = 'x;
                        endcase
                    end
                    3'b001: exp_reg_wrdata = 'x;
                    3'b010: exp_reg_wrdata = rs1 < rs2;
                    3'b011: exp_reg_wrdata = rs1 < rs2;
                    3'b100: exp_reg_wrdata = rs1 ^ rs2;
                    3'b101: exp_reg_wrdata = 'x;
                    3'b110: exp_reg_wrdata = rs1 | rs2;
                    3'b111: exp_reg_wrdata = rs1 & rs2;
                endcase
            end else if (itype == MADD) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == MSUB) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == NMSUB) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == NMADD) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == OPFP) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 'x;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == BRANCH) begin
                logic cond;
                
                imm = imm_b;
                
                unique case (op3)
                    3'b000: cond = rs1 == rs2;
                    3'b001: cond = rs1 != rs2;
                    3'b010: cond = 'x;
                    3'b011: cond = 'x;
                    3'b100: cond = $signed(rs1) < $signed(rs2);
                    3'b101: cond = $signed(rs1) >= $signed(rs2);
                    3'b110: cond = $unsigned(rs1) < $unsigned(rs2);
                    3'b111: cond = $unsigned(rs1) >= $unsigned(rs2);
                endcase
                
                xmem = 'x;
                
                exp_pc_next = pc + (cond ? imm : 4);
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b0;
                exp_reg_wraddr = 'x;
                exp_reg_wrdata_valid = 'x;
                exp_reg_wrdata = 'x;
            end else if (itype == JALR) begin
                imm = imm_i;
                
                xmem = 'x;
                
                exp_pc_next = rs1 + imm;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                exp_reg_wrdata = pc + 4;
            end else if (itype == JAL) begin
                imm = imm_j;
                
                xmem = 'x;
                
                exp_pc_next = pc + imm;
                exp_csr_wren = 1'b0;
                exp_csr_wraddr = 'x;
                exp_csr_wrdata = 'x;
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                exp_reg_wrdata = pc + 4;
            end else if (itype == SYSTEM) begin
                logic [REG_WIDTH-1:0] uimm;
                
                uimm = rs1_addr;
                
                xmem = 'x;
                
                exp_pc_next = pc + 4;
                exp_csr_wren = (op3[1:0] != '0) & (rs1_addr != '0);
                exp_csr_wraddr = csr_addr;
                unique case (op3)
                    3'b000: exp_csr_wrdata = 'x;
                    3'b001: exp_csr_wrdata = rs1;
                    3'b010: exp_csr_wrdata = csr | rs1;
                    3'b011: exp_csr_wrdata = csr & ~rs1;
                    3'b100: exp_csr_wrdata = 'x;
                    3'b101: exp_csr_wrdata = uimm;
                    3'b110: exp_csr_wrdata = csr | uimm;
                    3'b111: exp_csr_wrdata = csr & ~uimm;
                endcase
                exp_reg_wren = 1'b1;
                exp_reg_wraddr = rd_addr;
                exp_reg_wrdata_valid = 1'b1;
                exp_reg_wrdata = csr;
            end else begin
                $error("hart[%0d]$ Illegal instruction %0h @%0h", gi, instr, pc);
            end
            
            $fwrite(
                fd_decode,
                "[ %012d ] hart:%0d instr:%8h %6s rs1[%2h]:%8h rs2[%2h]:%8h imm=%8h rd[%2h] mr=%0d mw=%0d ma=%8h md=%8h\n",
                $time, gi, instr, itype.name(), rs1_addr, rs1, rs2_addr, rs2, imm, rd_addr,
                xmem.mem_rden, xmem.mem_wren, xmem.mem_addr, xmem.mem_wrdata
            );
        end
        
        always @(posedge clk iff (rst & pc_wr_en & pc_wr_hart_sel[gi])) begin
            assert (exp_pc_next === pc_wr_data) else begin
                $error("hart[%0d]$ pc_next: expected %0h, actual %0h", gi, exp_pc_next, pc_wr_data);
            end
        end
        
        always @(posedge clk iff (rst & csr_wr_en & csr_wr_hart_sel[gi])) begin
            assert (exp_csr_wren === csr_wr_en) else begin
                $error("hart[%0d]$ csr_wr_en: expected %0b, actual %0b", gi, exp_csr_wren, csr_wr_en);
            end
            
            if (csr_wr_en) begin
                assert (exp_csr_wraddr === csr_wr_addr) else begin
                    $error("hart[%0d]$ csr_wr_addr: expected %0h, actual %0h", gi, exp_csr_wraddr, csr_wr_addr);
                end
                
                assert (exp_csr_wrdata === csr_wr_data) else begin
                    $error("hart[%0d]$ csr_wr_data: expected %0h, actual %0h", gi, exp_csr_wrdata, csr_wr_data);
                end
            end
        end
        
        always @(posedge clk iff (rst & reg_wr_en & reg_wr_hart_sel[gi])) begin
            assert (exp_reg_wren === reg_wr_en) else begin
                $error("hart[%0d]$ reg_wr_en: expected %0b, actual %0b", gi, exp_reg_wren, reg_wr_en);
            end
            
            if (reg_wr_en) begin
                assert (exp_reg_wraddr === reg_wr_addr) else begin
                    $error("hart[%0d]$ reg_wr_addr: expected %0h, actual %0h", gi, exp_reg_wraddr, reg_wr_addr);
                end
                
                if (exp_reg_wrdata_valid) begin
                    assert (exp_reg_wrdata === reg_wr_data) else begin
                        $error("hart[%0d]$ reg_wr_data: expected %0h, actual %0h", gi, exp_reg_wrdata, reg_wr_data);
                    end
                end
            end
        end
    end
endmodule

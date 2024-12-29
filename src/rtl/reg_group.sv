module reg_group
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst,
    
    input  logic [NUM_HART-1:0]     pc_wr_hart_sel,
    input  logic                    pc_wr_en,
    input  logic [REG_WIDTH-1:0]    pc_wr_data,
    input  logic [NUM_HART-1:0]     pc_rd_hart_sel,
    output logic [REG_WIDTH-1:0]    pc,
    
    input  logic [NUM_HART-1:0]     csr_wr_hart_sel,
    input  logic                    csr_wr_en,
    input  logic [11:0]             csr_wr_addr,
    input  logic [REG_WIDTH-1:0]    csr_wr_data,
    input  logic [NUM_HART-1:0]     csr_rd_hart_sel,
    input  logic [11:0]             csr_rd_addr,
    output logic [REG_WIDTH-1:0]    csr,
    
    input  logic [NUM_HART-1:0]     reg_wr_hart_sel,
    input  logic                    reg_wr_en,
    input  logic [4:0]              reg_wr_addr,
    input  logic [REG_WIDTH-1:0]    reg_wr_data,
    input  logic [NUM_HART-1:0]     reg_rd_hart_sel,
    input  logic [4:0]              reg1_rd_addr,
    input  logic [4:0]              reg2_rd_addr,
    output logic [REG_WIDTH-1:0]    reg1,
    output logic [REG_WIDTH-1:0]    reg2
);
    logic [REG_WIDTH-1:0]   pc_list [NUM_HART];
    logic [REG_WIDTH-1:0]   csr_list [NUM_HART];
    logic [REG_WIDTH-1:0]   reg1_list [NUM_HART];
    logic [REG_WIDTH-1:0]   reg2_list [NUM_HART];
    
    for (genvar gi = 0 ; gi < NUM_HART ; gi++) begin: gen_reg_file
        logic regfile_pc_wren;
        logic regfile_csr_wren;
        logic regfile_reg_wren;
        
        always_comb regfile_pc_wren = pc_wr_en & pc_wr_hart_sel[gi];
        always_comb regfile_csr_wren = csr_wr_en & csr_wr_hart_sel[gi];
        always_comb regfile_reg_wren = reg_wr_en & reg_wr_hart_sel[gi];
        
        reg_file #(
            .REG_WIDTH      (REG_WIDTH)
        ) i_reg_file (
            .clk            (clk),
            .rst            (rst),
            .pc_wr_en       (regfile_pc_wren),
            .pc_wr_data     (pc_wr_data),
            .pc             (pc_list[gi]),
            .csr_wr_en      (regfile_csr_wren),
            .csr_wr_addr    (csr_wr_addr),
            .csr_wr_data    (csr_wr_data),
            .csr_rd_addr    (csr_rd_addr),
            .csr            (csr_list[gi]),
            .reg_wr_en      (regfile_reg_wren),
            .reg_wr_addr    (reg_wr_addr),
            .reg_wr_data    (reg_wr_data),
            .reg1_rd_addr   (reg1_rd_addr),
            .reg2_rd_addr   (reg2_rd_addr),
            .reg1           (reg1_list[gi]),
            .reg2           (reg2_list[gi])
        );
    end: gen_reg_file
    
    always_comb begin
        pc = '0;
        
        for (int unsigned i = 0 ; i < NUM_HART ; i++) begin
            pc |= pc_rd_hart_sel[i] ? pc_list[i] : '0;
        end
    end
    
    always_comb begin
        csr = '0;
        
        for (int unsigned i = 0 ; i < NUM_HART ; i++) begin
            csr |= csr_rd_hart_sel[i] ? csr_list[i] : '0;
        end
    end
    
    always_comb begin
        reg1 = '0;
        
        for (int unsigned i = 0 ; i < NUM_HART ; i++) begin
            reg1 |= reg_rd_hart_sel[i] ? reg1_list[i] : '0;
        end
    end
    
    always_comb begin
        reg2 = '0;
        
        for (int unsigned i = 0 ; i < NUM_HART ; i++) begin
            reg2 |= reg_rd_hart_sel[i] ? reg2_list[i] : '0;
        end
    end
endmodule

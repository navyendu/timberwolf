module core
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    int unsigned MEM_ADDR_WIDTH = 12,
    
    localparam int unsigned BYTES_PER_REG = REG_WIDTH / 8
)(
    input  logic                        clk,
    input  logic                        rst,
    
    output logic                        imem_rd_en,
    output logic [MEM_ADDR_WIDTH-1:0]   imem_rd_addr,
    
    input  logic                        imem_rd_ack,
    input  logic [REG_WIDTH-1:0]        imem_rd_data,
    
    output logic [MEM_ADDR_WIDTH-1:0]   dmem_addr,
    output logic                        dmem_rd_en,
    output logic                        dmem_wr_en,
    output logic [REG_WIDTH-1:0]        dmem_wr_data,
    output logic [BYTES_PER_REG-1:0]    dmem_wr_ben,
    
    input  logic                        dmem_rd_ack,
    input  logic [REG_WIDTH-1:0]        dmem_rd_data,
    
    input  logic                        dmem_wr_ack
);
    logic [NUM_HART-1:0]    pc_rd_hart_sel;
    logic [REG_WIDTH-1:0]   pc;
    
    logic [NUM_HART-1:0]    csr_rd_hart_sel;
    logic [11:0]            csr_rd_addr;
    logic [REG_WIDTH-1:0]   csr;
    
    logic [NUM_HART-1:0]    reg_rd_hart_sel;
    logic [4:0]             reg1_rd_addr;
    logic [4:0]             reg2_rd_addr;
    logic [REG_WIDTH-1:0]   reg1;
    logic [REG_WIDTH-1:0]   reg2;
    
    logic [NUM_HART-1:0]    pc_wr_hart_sel;
    logic                   pc_wr_en;
    logic [REG_WIDTH-1:0]   pc_wr_data;
    
    logic [NUM_HART-1:0]    csr_wr_hart_sel;
    logic                   csr_wr_en;
    logic [11:0]            csr_wr_addr;
    logic [REG_WIDTH-1:0]   csr_wr_data;
    
    logic [NUM_HART-1:0]    reg_wr_hart_sel;
    logic                   reg_wr_en;
    logic [4:0]             reg_wr_addr;
    logic [REG_WIDTH-1:0]   reg_wr_data;
    
    pipeline #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH),
        .MEM_ADDR_WIDTH     (MEM_ADDR_WIDTH)
    ) i_pipeline (
        .clk                (clk),
        .rst                (rst),
        .pc_rd_hart_sel     (pc_rd_hart_sel),
        .pc                 (pc),
        .imem_rd_en         (imem_rd_en),
        .imem_rd_addr       (imem_rd_addr),
        .imem_rd_ack        (imem_rd_ack),
        .imem_rd_data       (imem_rd_data),
        .csr_rd_hart_sel    (csr_rd_hart_sel),
        .csr_rd_addr        (csr_rd_addr),
        .csr                (csr),
        .reg_rd_hart_sel    (reg_rd_hart_sel),
        .reg1_rd_addr       (reg1_rd_addr),
        .reg2_rd_addr       (reg2_rd_addr),
        .reg1               (reg1),
        .reg2               (reg2),
        .dmem_addr          (dmem_addr),
        .dmem_rd_en         (dmem_rd_en),
        .dmem_wr_en         (dmem_wr_en),
        .dmem_wr_data       (dmem_wr_data),
        .dmem_wr_ben        (dmem_wr_ben),
        .dmem_rd_ack        (dmem_rd_ack),
        .dmem_rd_data       (dmem_rd_data),
        .dmem_wr_ack        (dmem_wr_ack),
        .pc_wr_hart_sel     (pc_wr_hart_sel),
        .pc_wr_en           (pc_wr_en),
        .pc_wr_data         (pc_wr_data),
        .csr_wr_hart_sel    (csr_wr_hart_sel),
        .csr_wr_en          (csr_wr_en),
        .csr_wr_addr        (csr_wr_addr),
        .csr_wr_data        (csr_wr_data),
        .reg_wr_hart_sel    (reg_wr_hart_sel),
        .reg_wr_en          (reg_wr_en),
        .reg_wr_addr        (reg_wr_addr),
        .reg_wr_data        (reg_wr_data)
    );
    
    reg_group #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH)
    ) i_reg_group (
        .clk                (clk),
        .rst                (rst),
        .pc_wr_hart_sel     (pc_wr_hart_sel),
        .pc_wr_en           (pc_wr_en),
        .pc_wr_data         (pc_wr_data),
        .pc_rd_hart_sel     (pc_rd_hart_sel),
        .pc                 (pc),
        .csr_wr_hart_sel    (csr_wr_hart_sel),
        .csr_wr_en          (csr_wr_en),
        .csr_wr_addr        (csr_wr_addr),
        .csr_wr_data        (csr_wr_data),
        .csr_rd_hart_sel    (csr_rd_hart_sel),
        .csr_rd_addr        (csr_rd_addr),
        .csr                (csr),
        .reg_wr_hart_sel    (reg_wr_hart_sel),
        .reg_wr_en          (reg_wr_en),
        .reg_wr_addr        (reg_wr_addr),
        .reg_wr_data        (reg_wr_data),
        .reg_rd_hart_sel    (reg_rd_hart_sel),
        .reg1_rd_addr       (reg1_rd_addr),
        .reg2_rd_addr       (reg2_rd_addr),
        .reg1               (reg1),
        .reg2               (reg2)
    );
endmodule

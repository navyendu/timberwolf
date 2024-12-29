module reg_file
#(
    int unsigned REG_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst,
    
    input  logic                    pc_wr_en,
    input  logic [REG_WIDTH-1:0]    pc_wr_data,
    output logic [REG_WIDTH-1:0]    pc,
    
    input  logic                    csr_wr_en,
    input  logic [11:0]             csr_wr_addr,
    input  logic [REG_WIDTH-1:0]    csr_wr_data,
    input  logic [11:0]             csr_rd_addr,
    output logic [REG_WIDTH-1:0]    csr,
    
    input  logic                    reg_wr_en,
    input  logic [4:0]              reg_wr_addr,
    input  logic [REG_WIDTH-1:0]    reg_wr_data,
    input  logic [4:0]              reg1_rd_addr,
    input  logic [4:0]              reg2_rd_addr,
    output logic [REG_WIDTH-1:0]    reg1,
    output logic [REG_WIDTH-1:0]    reg2
);
    always_ff @(posedge clk) begin
        if (!rst) begin
            pc <= '0;
        end else if (pc_wr_en) begin
            pc <= pc_wr_data;
        end
    end
    
    if (1) begin: gen_reg
        localparam int unsigned NUM_REG = 32;
        
        logic [REG_WIDTH-1:0]   reg_list        [NUM_REG];
        logic                   reg_wren_1hot   [NUM_REG-1:0];
        
        always_comb begin
            reg_wren_1hot = '{ default: '0 };
            reg_wren_1hot[reg_wr_addr] = reg_wr_en;
        end
        
        always_comb reg_list[0] = '0;
        for (genvar gi = 1 ; gi < NUM_REG ; gi++) begin: gen_list
            always_ff @(posedge clk) begin
                if (!rst) begin
                    reg_list[gi] <= '0;
                end else if (reg_wren_1hot[gi]) begin
                    reg_list[gi] <= reg_wr_data;
                end
            end
        end
        
        always_comb reg1 = reg_list[reg1_rd_addr];
        always_comb reg2 = reg_list[reg2_rd_addr];
    end: gen_reg
    
    if (1) begin: gen_csr
        localparam int unsigned NUM_CSR = 32;
        localparam int unsigned CSR_ADDR_WIDTH = $clog2(NUM_CSR);
        
        logic [REG_WIDTH-1:0]       csr_list [NUM_CSR];
        
        logic [CSR_ADDR_WIDTH-1:0]  csr_wraddr_trimmed;
        logic [CSR_ADDR_WIDTH-1:0]  csr_rdaddr_trimmed;
        
        always_comb csr_wraddr_trimmed = csr_wr_addr[CSR_ADDR_WIDTH-1:0];
        always_comb csr_rdaddr_trimmed = csr_rd_addr[CSR_ADDR_WIDTH-1:0];
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                csr_list <= '{ default: '0 };
            end else if (csr_wr_en) begin
                csr_list[csr_wraddr_trimmed] <= csr_wr_data;
            end
        end
        
        always_comb csr = csr_list[csr_rdaddr_trimmed];
    end: gen_csr
endmodule

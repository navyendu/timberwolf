module fetch
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    int unsigned MEM_ADDR_WIDTH = REG_WIDTH,
    type T_in = logic,
    type T_out = logic
)(
    input  T_in                         in,
    
    output logic [NUM_HART-1:0]         pc_rd_hart_sel,
    input  logic [REG_WIDTH-1:0]        pc,
    
    output logic                        imem_rd_en,
    output logic [MEM_ADDR_WIDTH-1:0]   imem_rd_addr,
    
    input  logic                        imem_rd_ack,
    input  logic [REG_WIDTH-1:0]        imem_rd_data,
    
    output T_out                        out
);
    always_comb pc_rd_hart_sel = in.hart_sel;
    
    always_comb imem_rd_en = in.hart_valid;
    always_comb imem_rd_addr = pc[MEM_ADDR_WIDTH-1:0];
    
    always_comb out = '{
        hart_sel:       in.hart_sel,
        instr_valid:    imem_rd_ack,
        instr:          imem_rd_data,
        pc:             pc
    };
endmodule

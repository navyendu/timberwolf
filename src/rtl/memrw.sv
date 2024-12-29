module memrw
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    int unsigned MEM_ADDR_WIDTH = 32,
    type T_in = logic,
    type T_out = logic,
    
    localparam int unsigned BYTES_PER_REG = REG_WIDTH / 8
)(
    input  T_in                         in,
    
    output logic [MEM_ADDR_WIDTH-1:0]   dmem_addr,
    output logic                        dmem_rd_en,
    output logic                        dmem_wr_en,
    output logic [REG_WIDTH-1:0]        dmem_wr_data,
    output logic [BYTES_PER_REG-1:0]    dmem_wr_ben,
    
    input  logic                        dmem_rd_ack,
    input  logic [REG_WIDTH-1:0]        dmem_rd_data,
    
    input  logic                        dmem_wr_ack,
    
    output logic [NUM_HART-1:0]         pc_wr_hart_sel,
    output logic                        pc_wr_en,
    output logic [REG_WIDTH-1:0]        pc_wr_data,
    
    output T_out                        out
);
    localparam int unsigned MEM_LOW_WIDTH = $clog2(REG_WIDTH / 8);
    
    logic [MEM_LOW_WIDTH-1:0] mem_reg_byte_addr;
    
    logic pc_sel_j;
    logic [REG_WIDTH-1:0] lane_y;
    
    logic reg_wr_en;
    
    always_comb mem_reg_byte_addr = in.lane_k[MEM_LOW_WIDTH-1:0];
    
    always_comb dmem_addr = { in.lane_k[MEM_ADDR_WIDTH-1:MEM_LOW_WIDTH], { MEM_LOW_WIDTH { 1'b0 } } };
    always_comb dmem_rd_en = in.mem_rd_en;
    always_comb dmem_wr_en = in.mem_wr_en;
    always_comb dmem_wr_data = in.lane_j;
    always_comb dmem_wr_ben = in.mem_wr_ben << mem_reg_byte_addr;
    
    always_comb pc_sel_j = in.branch ? in.lane_k[0] : in.pc_sel_j;
    
    always_comb pc_wr_hart_sel = in.hart_sel;
    always_comb pc_wr_en = in.pc_wr_en & (
        (in.mem_rd_en ? dmem_rd_ack : 1'b1) |
        (in.mem_wr_en ? dmem_wr_ack : 1'b1)
    );
    always_comb pc_wr_data =
        in.pc_sel_k ? in.lane_k :
        pc_sel_j ? in.lane_j :
        in.lane_i;
    
    always_comb lane_y =
        in.lane_y_sel_k ? in.lane_k :
        in.lane_y_sel_j ? in.lane_j :
        in.lane_i;
    
    always_comb begin
        unique if (in.mem_rd_en) begin
            reg_wr_en = in.reg_wr_en & dmem_rd_ack;
        end else begin
            reg_wr_en = in.reg_wr_en;
        end
    end
    
    always_comb out = '{
        hart_sel:           in.hart_sel,
        csr_wr_en:          in.csr_wr_en,
        csr_wr_addr:        in.csr_wr_addr,
        reg_wr_en:          reg_wr_en,
        reg_wr_sel_z:       in.mem_rd_en,
        reg_wr_size:        in.reg_wr_size,
        reg_wr_sign_ext:    in.reg_wr_sign_ext,
        reg_wr_shift:       in.lane_k[MEM_LOW_WIDTH-1:0],
        reg_wr_addr:        in.reg_wr_addr,
        lane_x:             in.lane_k,
        lane_y:             lane_y,
        lane_z:             dmem_rd_data
    };
endmodule

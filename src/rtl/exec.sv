module exec
#(
    int unsigned REG_WIDTH = 32,
    type T_in = logic,
    type T_tube_valid = logic,
    type T_tube_op = logic,
    type T_tube_out = logic,
    type T_out = logic,
    T_tube_valid TUBE_EN = '{ default: '0 }
)(
    input  logic    clk,
    input  logic    rst,
    
    input  T_in     in,
    output T_out    out
);
    logic [REG_WIDTH-1:0]   pc;
    
    logic [REG_WIDTH-1:0]   lane_i;
    logic [REG_WIDTH-1:0]   lane_j;
    
    T_tube_valid            tube_out_valid;
    T_tube_out              tube_out_data;
    
    logic                   tube_muxed_valid;
    logic [REG_WIDTH-1:0]   tube_muxed_data;
    
    logic   reg_wr_en;
    
    always_comb pc = in.lane_a;
    
    always_comb lane_i = pc + 4;
    always_comb lane_j = in.lane_b + (in.lane_j_add_pc ? pc : '0);
    
    if (TUBE_EN.tube_0c) begin: gen_tube_0c_en
        tube_0c #(
            .REG_WIDTH  (REG_WIDTH),
            .T_tube_op  (T_tube_op)
        ) i_tube_0c (
            .in_valid   (in.exec_tube_sel.tube_0c),
            .in_data1   (in.lane_c),
            .in_data2   (in.lane_d),
            .op         (in.exec_tube_op),
            .out_valid  (tube_out_valid.tube_0c),
            .out_data   (tube_out_data.tube_0c)
        );
    end else begin: gen_tube_0c_dis
        always_comb tube_out_valid.tube_0c = '0;
        always_comb tube_out_data.tube_0c = '0;
    end
    
    if (TUBE_EN.tube_4c) begin: gen_tube_4c_en
        tube_4c #(
            .REG_WIDTH  (REG_WIDTH),
            .T_tube_op  (T_tube_op)
        ) i_tube_4c (
            .clk        (clk),
            .rst        (rst),
            .in_valid   (in.exec_tube_sel.tube_4c),
            .in_data1   (in.lane_c),
            .in_data2   (in.lane_d),
            .op         (in.exec_tube_op),
            .out_valid  (tube_out_valid.tube_4c),
            .out_data   (tube_out_data.tube_4c)
        );
    end else begin: gen_tube_4c_dis
        always_comb tube_out_valid.tube_4c = '0;
        always_comb tube_out_data.tube_4c = '0;
    end
    
    if (TUBE_EN.tube_8c) begin: gen_tube_8c_en
        tube_8c #(
            .REG_WIDTH  (REG_WIDTH),
            .T_tube_op  (T_tube_op)
        ) i_tube_8c (
            .clk        (clk),
            .rst        (rst),
            .in_valid   (in.exec_tube_sel.tube_8c),
            .in_data1   (in.lane_c),
            .in_data2   (in.lane_d),
            .op         (in.exec_tube_op),
            .out_valid  (tube_out_valid.tube_8c),
            .out_data   (tube_out_data.tube_8c)
        );
    end else begin: gen_tube_8c_dis
        always_comb tube_out_valid.tube_8c = '0;
        always_comb tube_out_data.tube_8c = '0;
    end
    
    assert property (@(posedge clk) $onehot0(tube_out_valid)) else begin
        $error("tube_out_valid (%0h) is not one-hot-zero", tube_out_valid);
    end
    
    always_comb tube_muxed_valid = tube_out_valid != '0;
    always_comb begin
        unique case (1'b1)
            tube_out_valid.tube_0c: tube_muxed_data = tube_out_data.tube_0c;
            tube_out_valid.tube_4c: tube_muxed_data = tube_out_data.tube_4c;
            tube_out_valid.tube_8c: tube_muxed_data = tube_out_data.tube_8c;
            default:                tube_muxed_data = '0;
        endcase
    end
    
    always_comb reg_wr_en = in.reg_wr_en &
        ((in.exec_tube_sel == '0) | tube_muxed_valid);
    
    always_comb out = '{
        hart_sel:           in.hart_sel,
        pc_wr_en:           in.pc_wr_en,
        branch:             in.branch,
        pc_sel_j:           in.pc_sel_j,
        pc_sel_k:           in.pc_sel_k,
        lane_y_sel_j:       in.lane_y_sel_j,
        lane_y_sel_k:       in.lane_y_sel_k,
        mem_rd_en:          in.mem_rd_en,
        mem_wr_en:          in.mem_wr_en,
        mem_wr_ben:         in.mem_wr_ben,
        csr_wr_en:          in.csr_wr_en,
        csr_wr_addr:        in.csr_wr_addr,
        reg_wr_en:          reg_wr_en,
        reg_wr_size:        in.reg_wr_size,
        reg_wr_sign_ext:    in.reg_wr_sign_ext,
        reg_wr_addr:        in.reg_wr_addr,
        lane_i:             lane_i,
        lane_j:             lane_j,
        lane_k:             tube_muxed_data
    };
endmodule

module regwr
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    type T_in = logic
)(
    input  T_in                     in,
    
    output logic [NUM_HART-1:0]     csr_wr_hart_sel,
    output logic                    csr_wr_en,
    output logic [11:0]             csr_wr_addr,
    output logic [REG_WIDTH-1:0]    csr_wr_data,
    
    output logic [NUM_HART-1:0]     reg_wr_hart_sel,
    output logic                    reg_wr_en,
    output logic [4:0]              reg_wr_addr,
    output logic [REG_WIDTH-1:0]    reg_wr_data
);
    localparam int unsigned SHIFT_AMOUNT_WIDTH = $clog2(REG_WIDTH);
    
    logic [SHIFT_AMOUNT_WIDTH-1:0] shift_amount;
    
    logic [REG_WIDTH-1:0] data_shifted;
    logic [REG_WIDTH-1:0] data_sign_ext;
    
    always_comb shift_amount = in.reg_wr_shift * 8;
    
    always_comb data_shifted = in.lane_z >> shift_amount;
    for (genvar gi = 0 ; gi < REG_WIDTH ; gi++) begin: gen_data_sign_ext
        if (gi < 8) begin: gen_7_0
            always_comb data_sign_ext[gi] = data_shifted[gi];
        end else if (gi < 16) begin: gen_15_8
            always_comb begin
                unique case (in.reg_wr_size)
                    2'b00:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[7];
                    default: data_sign_ext[gi] = data_shifted[gi];
                endcase
            end
        end else if (gi < 32) begin: gen_31_16
            always_comb begin
                unique case (in.reg_wr_size)
                    2'b00:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[7];
                    2'b01:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[15];
                    default: data_sign_ext[gi] = data_shifted[gi];
                endcase
            end
        end else begin: gen_63_32
            always_comb begin
                unique case (in.reg_wr_size)
                    2'b00:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[7];
                    2'b01:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[15];
                    2'b10:   data_sign_ext[gi] = in.reg_wr_sign_ext & data_shifted[31];
                    default: data_sign_ext[gi] = data_shifted[gi];
                endcase
            end
        end
    end
    
    always_comb csr_wr_hart_sel = in.hart_sel;
    always_comb csr_wr_en = in.csr_wr_en;
    always_comb csr_wr_addr = in.csr_wr_addr;
    always_comb csr_wr_data = in.lane_x;
    
    always_comb reg_wr_hart_sel = in.hart_sel;
    always_comb reg_wr_en = in.reg_wr_en;
    always_comb reg_wr_addr = in.reg_wr_addr;
    always_comb reg_wr_data = in.reg_wr_sel_z ? data_sign_ext : in.lane_y;
endmodule

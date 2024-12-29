module tube_8c
#(
    int unsigned REG_WIDTH = 32,
    type T_tube_op = logic
)(
    input  logic                    clk,
    input  logic                    rst,
    
    input  logic                    in_valid,
    input  logic [REG_WIDTH-1:0]    in_data1,
    input  logic [REG_WIDTH-1:0]    in_data2,
    input  T_tube_op                op,
    
    output logic                    out_valid,
    output logic [REG_WIDTH-1:0]    out_data
);
    // Not implemented
    // This module is a proof-of-concept placeholder
    // for an 8-clock tube
    
    typedef struct packed {
        logic                   valid;
        logic [REG_WIDTH-1:0]   data;
    } stage0_type;
    
    stage0_type stage_d [8];
    stage0_type stage [8];
    
    always_comb stage_d[0] = '{
        valid: in_valid,
        data:  (in_data1 << 8) | in_data2
    };
    for (genvar gi = 1 ; gi < 8 ; gi++) begin: gen_stage_d
        always_comb stage_d[gi] = stage[gi-1];
    end
    
    for (genvar gi = 0 ; gi < 8 ; gi++) begin: gen_stage
        logic en;
        
        always_comb en = stage_d[gi].valid | stage[gi].valid;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                stage[gi] <= '0;
            end else if (en) begin
                stage[gi] <= stage_d[gi];
            end
        end
    end
    
    always_comb out_valid = stage[7].valid;
    always_comb out_data = stage[7].data;
endmodule

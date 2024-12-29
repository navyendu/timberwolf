module tube_4c
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
    typedef struct packed {
        logic                   valid;
        logic [REG_WIDTH-1:0]   data1;
        logic [REG_WIDTH-1:0]   data2;
    } stage0_type;
    
    typedef struct packed {
        logic                   valid;
        logic [REG_WIDTH-1:0]   data1;
        logic [REG_WIDTH-1:0]   data2;
    } stage1_type;
    
    typedef struct packed {
        logic                   valid;
        logic [REG_WIDTH-1:0]   data;
    } stage2_type;
    
    typedef struct packed {
        logic                   valid;
        logic [REG_WIDTH-1:0]   data;
    } stage3_type;
    
    logic [2*REG_WIDTH-1:0] mul;
    
    logic       stage0_en;
    stage0_type stage0_d;
    stage0_type stage0;
    
    logic       stage1_en;
    stage1_type stage1_d;
    stage1_type stage1;
    
    logic       stage2_en;
    stage2_type stage2_d;
    stage2_type stage2;
    
    logic       stage3_en;
    stage3_type stage3_d;
    stage3_type stage3;
    
    always_comb stage0_en = stage0_d.valid | stage0.valid;
    always_comb stage0_d = '{
        valid: in_valid,
        data1: in_data1,
        data2: in_data2
    };
    always_ff @(posedge clk) begin
        if (!rst) begin
            stage0 <= '0;
        end else if (stage0_en) begin
            stage0 <= stage0_d;
        end
    end
    
    always_comb stage1_en = stage1_d.valid | stage1.valid;
    always_comb stage1_d = '{
        valid: stage0.valid,
        data1: stage0.data1,
        data2: stage0.data2
    };
    always_ff @(posedge clk) begin
        if (!rst) begin
            stage1 <= '0;
        end else if (stage1_en) begin
            stage1 <= stage1_d;
        end
    end
    
    always_comb mul = stage1.data1 * stage1.data2;
    
    always_comb stage2_en = stage2_d.valid | stage2.valid;
    always_comb stage2_d = '{
        valid: stage1.valid,
        data:  mul[REG_WIDTH-1:0]
    };
    always_ff @(posedge clk) begin
        if (!rst) begin
            stage2 <= '0;
        end else if (stage2_en) begin
            stage2 <= stage2_d;
        end
    end
    
    always_comb stage3_en = stage3_d.valid | stage3.valid;
    always_comb stage3_d = '{
        valid: stage2.valid,
        data:  stage2.data
    };
    always_ff @(posedge clk) begin
        if (!rst) begin
            stage3 <= '0;
        end else if (stage3_en) begin
            stage3 <= stage3_d;
        end
    end
    
    always_comb out_valid = stage3.valid;
    always_comb out_data = stage3.data;
endmodule

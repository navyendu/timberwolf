module tube_0c
#(
    int unsigned REG_WIDTH = 32,
    type T_tube_op = logic
)(
    input  logic                    in_valid,
    input  logic [REG_WIDTH-1:0]    in_data1,
    input  logic [REG_WIDTH-1:0]    in_data2,
    input  T_tube_op                op,
    
    output logic                    out_valid,
    output logic [REG_WIDTH-1:0]    out_data
);
    localparam int unsigned SHAMT_WIDTH = $clog2(REG_WIDTH);
    
    logic sign1;
    logic sign2;
    
    logic [REG_WIDTH-1:0] data1;
    logic [REG_WIDTH-1:0] data2;
    
    logic [SHAMT_WIDTH-1:0] shamt;
    
    logic [REG_WIDTH-1:0] res_sum;
    logic res_carry;
    
    logic res_eq;
    logic res_ne;
    logic res_lt;
    logic res_ge;
    
    logic [REG_WIDTH-1:0] res_xor;
    logic [REG_WIDTH-1:0] res_or;
    logic [REG_WIDTH-1:0] res_and;
    
    logic [REG_WIDTH-1:0] res_sll;
    logic [REG_WIDTH-1:0] res_srl;
    logic [REG_WIDTH-1:0] res_sra;
    logic [REG_WIDTH-1:0] res_sr;
    
    logic [REG_WIDTH-1:0] final_sum;
    logic [REG_WIDTH-1:0] final_bool;
    logic [REG_WIDTH-1:0] final_bitvec;
    logic [REG_WIDTH-1:0] final_shift;
    
    always_comb sign1 = in_data1[REG_WIDTH-1];
    always_comb sign2 = in_data2[REG_WIDTH-1];
    
    always_comb data1 = in_data1;
    always_comb data2 = op.tube_0c.inv2 ? ~in_data2 : in_data2;
    
    always_comb shamt = data2[SHAMT_WIDTH-1:0];
    
    // If the tool is smart, it'll use exactly one `REG_WIDTH`-bit full adder
    // With inv2 == 1 && cin == 1, we get data1 - data2
    always_comb { res_carry, res_sum } = data1 + data2 + op.tube_0c.cin;
    
    //   sign sign1 sign2 carry      ?
    // -------------------------------
    //      0     0     0     0     lt
    //      0     0     0     1     gt
    //      0     0     1     0     lt
    //      0     0     1     1      -
    //      0     1     0     0      -
    //      0     1     0     1     gt
    //      0     1     1     0     lt
    //      0     1     1     1     gt
    //      1     0     0     0     lt
    //      1     0     0     1     gt
    //      1     0     1     0     gt
    //      1     0     1     1      -
    //      1     1     0     0      -
    //      1     1     0     1     lt
    //      1     1     1     0     lt
    //      1     1     1     1     gt
    always_comb res_eq = (res_xor == '0);
    always_comb res_ne = ~res_eq;
    always_comb res_lt = (op.tube_0c.sign & (sign1 ^ sign2)) ? res_carry : ~res_carry;
    always_comb res_ge = ~res_lt;
    
    always_comb res_xor = data1 ^ data2;
    always_comb res_or = data1 | data2;
    always_comb res_and = data1 & data2;
    
    always_comb res_sll = data1 << shamt;
    always_comb res_srl = data1 >> shamt;
    always_comb res_sra = $signed(data1) >>> shamt;
    
    always_comb res_sr = op.tube_0c.sign ? res_sra : res_srl;
    
    always_comb final_sum = res_sum;
    always_comb begin
        unique case (op.tube_0c.rsel)
            2'b00:   final_bool = { { REG_WIDTH-1 {1'b0} }, res_eq };
            2'b01:   final_bool = { { REG_WIDTH-1 {1'b0} }, res_ne };
            2'b10:   final_bool = { { REG_WIDTH-1 {1'b0} }, res_lt };
            2'b11:   final_bool = { { REG_WIDTH-1 {1'b0} }, res_ge };
            default: final_bool = 'x;
        endcase
    end
    always_comb begin
        unique case (op.tube_0c.rsel)
            2'b00:   final_bitvec = res_xor;
            2'b01:   final_bitvec = 'x;
            2'b10:   final_bitvec = res_or;
            2'b11:   final_bitvec = res_and;
            default: final_bitvec = 'x;
        endcase
    end
    always_comb begin
        unique case (op.tube_0c.rsel)
            2'b00:   final_shift = res_sll;
            2'b01:   final_shift = 'x;
            2'b10:   final_shift = res_sr;
            2'b11:   final_shift = 'x;
            default: final_shift = 'x;
        endcase
    end
    
    always_comb out_valid = in_valid;
    always_comb begin
        unique case (op.tube_0c.fsel)
            2'b00:   out_data = final_sum;
            2'b01:   out_data = final_bool;
            2'b10:   out_data = final_bitvec;
            2'b11:   out_data = final_shift;
            default: out_data = '0;
        endcase
    end
endmodule

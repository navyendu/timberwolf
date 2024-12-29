module tube_tracker
#(
    parameter int unsigned DEPTH = 4,
    type T = logic
)(
    input  logic    clk,
    input  logic    rst,
    
    input  T        in,
    output T        vec [DEPTH]
);
    T vec_d [DEPTH];
    
    always_comb vec_d[DEPTH-1] = in;
    for (genvar gi = 0 ; gi < DEPTH-1 ; gi++) begin: gen_vec_d
        always_comb vec_d[gi] = vec[gi+1];
    end
    
    for (genvar gi = 0 ; gi < DEPTH ; gi++) begin: gen_vec
        logic en;
        
        always_comb en = vec_d[gi].valid | vec[gi].valid;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                vec[gi] <= '0;
            end else if (en) begin
                vec[gi] <= vec_d[gi];
            end
        end
    end
endmodule


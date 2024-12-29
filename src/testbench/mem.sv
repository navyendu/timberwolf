module mem
#(
    int unsigned AWIDTH = 1,
    int unsigned DWIDTH = 32,
    bit FLOP_OUT = 1'b0,
    
    localparam int unsigned DBYTES = DWIDTH / 8
)(
    input  logic                clk,
    
    input  logic                wren,
    input  logic [AWIDTH-1:0]   wraddr,
    input  logic [DWIDTH-1:0]   wrdata,
    input  logic [DBYTES-1:0]   wrben,
    
    input  logic [AWIDTH-1:0]   rdaddr,
    output logic [DWIDTH-1:0]   rddata
);
    localparam int unsigned DEPTH = 2 ** AWIDTH;
    
    logic [DWIDTH-1:0]  mem [DEPTH];
    
    for (genvar gi = 0 ; gi < DBYTES ; gi++) begin
        always_ff @(posedge clk) begin
            if (wren && wrben[gi]) begin
                mem[wraddr][gi*8 +: 8] <= wrdata[gi*8 +: 8];
            end
        end
    end
    
    if (FLOP_OUT) begin: gen_flop_out
        always_ff @(posedge clk) begin
            rddata <= mem[rdaddr];
        end
    end else begin: gen_comb_out
        always_comb rddata = mem[rdaddr];
    end
endmodule

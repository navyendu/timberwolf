module pipeline
#(
    int unsigned NUM_HART = 4,
    int unsigned REG_WIDTH = 32,
    int unsigned MEM_ADDR_WIDTH = 32,
    
    localparam int unsigned BYTES_PER_REG = REG_WIDTH / 8
)(
    input  logic                        clk,
    input  logic                        rst,
    
    output logic [NUM_HART-1:0]         pc_rd_hart_sel,
    input  logic [REG_WIDTH-1:0]        pc,
    
    output logic                        imem_rd_en,
    output logic [MEM_ADDR_WIDTH-1:0]   imem_rd_addr,
    
    input  logic                        imem_rd_ack,
    input  logic [REG_WIDTH-1:0]        imem_rd_data,
    
    output logic [NUM_HART-1:0]         csr_rd_hart_sel,
    output logic [11:0]                 csr_rd_addr,
    input  logic [REG_WIDTH-1:0]        csr,
    
    output logic [NUM_HART-1:0]         reg_rd_hart_sel,
    output logic [4:0]                  reg1_rd_addr,
    output logic [4:0]                  reg2_rd_addr,
    input  logic [REG_WIDTH-1:0]        reg1,
    input  logic [REG_WIDTH-1:0]        reg2,
    
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
    
    output logic [NUM_HART-1:0]         csr_wr_hart_sel,
    output logic                        csr_wr_en,
    output logic [11:0]                 csr_wr_addr,
    output logic [REG_WIDTH-1:0]        csr_wr_data,
    
    output logic [NUM_HART-1:0]         reg_wr_hart_sel,
    output logic                        reg_wr_en,
    output logic [4:0]                  reg_wr_addr,
    output logic [REG_WIDTH-1:0]        reg_wr_data
);
    localparam int unsigned MEM_LOW_WIDTH = $clog2(REG_WIDTH / 8);
    
    typedef struct packed {
        logic [NUM_HART-1:0]        hart_sel;
        logic                       hart_valid;
    } hart_fetch_type;
    
    typedef struct packed {
        logic [NUM_HART-1:0]        hart_sel;
        logic                       instr_valid;
        logic [31:0]                instr;
        logic [REG_WIDTH-1:0]       pc;
    } fetch_decode_type;
    
    typedef struct packed {
        logic                       tube_0c;
        logic                       tube_4c;
        logic                       tube_8c;
    } tube_valid_type;
    
    typedef struct packed {
        logic                       sign;
        logic                       inv2;
        logic                       cin;
        logic [1:0]                 rsel;
        logic [1:0]                 fsel;
    } tube_op_0c_type;
    
    typedef struct packed {
        logic [6:0]                 rsvd;
    } tube_op_4c_type;
    
    typedef struct packed {
        logic [6:0]                 rsvd;
    } tube_op_8c_type;
    
    typedef union packed {
        tube_op_0c_type             tube_0c;
        tube_op_4c_type             tube_4c;
        tube_op_8c_type             tube_8c;
    } tube_op_type;
    
    typedef struct packed {
        logic [REG_WIDTH-1:0]       tube_0c;
        logic [REG_WIDTH-1:0]       tube_4c;
        logic [REG_WIDTH-1:0]       tube_8c;
    } tube_out_type;
    
    typedef struct packed {
        logic [NUM_HART-1:0]        hart_sel;
        logic                       lane_j_add_pc;
        tube_valid_type             exec_tube_sel;
        tube_op_type                exec_tube_op;
        logic                       pc_wr_en;
        logic                       branch;
        logic                       pc_sel_j;
        logic                       pc_sel_k;
        logic                       lane_y_sel_j;
        logic                       lane_y_sel_k;
        logic                       mem_rd_en;
        logic                       mem_wr_en;
        logic [BYTES_PER_REG-1:0]   mem_wr_ben;
        logic                       csr_wr_en;
        logic [11:0]                csr_wr_addr;
        logic                       reg_wr_en;
        logic [1:0]                 reg_wr_size;
        logic                       reg_wr_sign_ext;
        logic [4:0]                 reg_wr_addr;
        logic [REG_WIDTH-1:0]       lane_a;
        logic [REG_WIDTH-1:0]       lane_b;
        logic [REG_WIDTH-1:0]       lane_c;
        logic [REG_WIDTH-1:0]       lane_d;
    } decode_exec_type;
    
    typedef struct packed {
        logic [NUM_HART-1:0]        hart_sel;
        logic                       pc_wr_en;
        logic                       branch;
        logic                       pc_sel_j;
        logic                       pc_sel_k;
        logic                       lane_y_sel_j;
        logic                       lane_y_sel_k;
        logic                       mem_rd_en;
        logic                       mem_wr_en;
        logic [BYTES_PER_REG-1:0]   mem_wr_ben;
        logic                       csr_wr_en;
        logic [11:0]                csr_wr_addr;
        logic                       reg_wr_en;
        logic [1:0]                 reg_wr_size;
        logic                       reg_wr_sign_ext;
        logic [4:0]                 reg_wr_addr;
        logic [REG_WIDTH-1:0]       lane_i;
        logic [REG_WIDTH-1:0]       lane_j;
        logic [REG_WIDTH-1:0]       lane_k;
    } exec_memrw_type;
    
    typedef struct packed {
        logic [NUM_HART-1:0]        hart_sel;
        logic                       csr_wr_en;
        logic                       reg_wr_en;
        logic [11:0]                csr_wr_addr;
        logic                       reg_wr_sel_z;
        logic [1:0]                 reg_wr_size;
        logic                       reg_wr_sign_ext;
        logic [MEM_LOW_WIDTH-1:0]   reg_wr_shift;
        logic [4:0]                 reg_wr_addr;
        logic [REG_WIDTH-1:0]       lane_x;
        logic [REG_WIDTH-1:0]       lane_y;
        logic [REG_WIDTH-1:0]       lane_z;
    } memrw_regwr_type;
    
    hart_fetch_type hart_fetch_pipe;
    fetch_decode_type fetch_decode_pipe_d;
    fetch_decode_type fetch_decode_pipe;
    decode_exec_type decode_exec_pipe_d;
    decode_exec_type decode_exec_pipe;
    exec_memrw_type exec_memrw_pipe_d;
    exec_memrw_type exec_memrw_pipe;
    memrw_regwr_type memrw_regwr_pipe_d;
    memrw_regwr_type memrw_regwr_pipe;
    
    if (1) begin: gen_hart_fetch_pipe
        localparam hart_fetch_type RSTVAL = '{
            hart_sel:   '0,
            hart_valid: 1'b0
        };
        
        localparam hart_fetch_type INITVAL = '{
            hart_sel:   { { NUM_HART-1 { 1'b0 } }, 1'b1 },
            hart_valid: 1'b1
        };
        
        logic init;
        
        logic [NUM_HART-1:0] hart_sel_shift;
        hart_fetch_type d;
        
        always_comb init = rst & ~hart_fetch_pipe.hart_valid;
        
        always_comb hart_sel_shift = {
            hart_fetch_pipe.hart_sel[NUM_HART-2:0], hart_fetch_pipe.hart_sel[NUM_HART-1]
        };
        
        always_comb d = '{
            hart_valid: rst,
            hart_sel:   hart_sel_shift
        };
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                hart_fetch_pipe <= RSTVAL;
            end else if (init) begin
                hart_fetch_pipe <= INITVAL;
            end else begin
                hart_fetch_pipe <= d;
            end
        end
    end: gen_hart_fetch_pipe
    
    fetch #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH),
        .MEM_ADDR_WIDTH     (MEM_ADDR_WIDTH),
        .T_in               (hart_fetch_type),
        .T_out              (fetch_decode_type)
    ) i_fetch (
        .in                 (hart_fetch_pipe),
        .pc_rd_hart_sel     (pc_rd_hart_sel),
        .pc                 (pc),
        .imem_rd_en         (imem_rd_en),
        .imem_rd_addr       (imem_rd_addr),
        .imem_rd_ack        (imem_rd_ack),
        .imem_rd_data       (imem_rd_data),
        .out                (fetch_decode_pipe_d)
    );
    
    if (1) begin: gen_fetch_decode_pipe
        logic en;
        
        always_comb en =
            fetch_decode_pipe_d.instr_valid |
            fetch_decode_pipe.instr_valid;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                fetch_decode_pipe <= '0;
            end else if (en) begin
                fetch_decode_pipe <= fetch_decode_pipe_d;
            end
        end
    end: gen_fetch_decode_pipe
    
    decode #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH),
        .T_in               (fetch_decode_type),
        .T_tube_valid       (tube_valid_type),
        .T_tube_op          (tube_op_type),
        .T_out              (decode_exec_type)
    ) i_decode (
        .clk                (clk),
        .rst                (rst),
        .in                 (fetch_decode_pipe),
        .csr_rd_hart_sel    (csr_rd_hart_sel),
        .csr_rd_addr        (csr_rd_addr),
        .csr                (csr),
        .reg_rd_hart_sel    (reg_rd_hart_sel),
        .reg1_rd_addr       (reg1_rd_addr),
        .reg2_rd_addr       (reg2_rd_addr),
        .reg1               (reg1),
        .reg2               (reg2),
        .out                (decode_exec_pipe_d)
    );
    
    if (1) begin: gen_decode_exec_pipe
        logic en;
        
        always_comb en =
            decode_exec_pipe_d.pc_wr_en |
            decode_exec_pipe_d.mem_rd_en | decode_exec_pipe_d.mem_wr_en |
            decode_exec_pipe_d.csr_wr_en | decode_exec_pipe_d.reg_wr_en |
            decode_exec_pipe.pc_wr_en |
            decode_exec_pipe.mem_rd_en | decode_exec_pipe.mem_wr_en |
            decode_exec_pipe.csr_wr_en | decode_exec_pipe.reg_wr_en;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                decode_exec_pipe <= '0;
            end else if (en) begin
                decode_exec_pipe <= decode_exec_pipe_d;
            end
        end
    end: gen_decode_exec_pipe
    
    exec #(
        .REG_WIDTH          (REG_WIDTH),
        .T_in               (decode_exec_type),
        .T_tube_valid       (tube_valid_type),
        .T_tube_op          (tube_op_type),
        .T_tube_out         (tube_out_type),
        .T_out              (exec_memrw_type),
        .TUBE_EN            ('1)
    ) i_exec (
        .clk                (clk),
        .rst                (rst),
        .in                 (decode_exec_pipe),
        .out                (exec_memrw_pipe_d)
    );
    
    if (1) begin: gen_exec_memrw_pipe
        logic en;
        
        always_comb en =
            exec_memrw_pipe_d.pc_wr_en |
            exec_memrw_pipe_d.mem_rd_en | exec_memrw_pipe_d.mem_wr_en |
            exec_memrw_pipe_d.csr_wr_en | exec_memrw_pipe_d.reg_wr_en |
            exec_memrw_pipe.pc_wr_en |
            exec_memrw_pipe.mem_rd_en | exec_memrw_pipe.mem_wr_en |
            exec_memrw_pipe.csr_wr_en | exec_memrw_pipe.reg_wr_en;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                exec_memrw_pipe <= '0;
            end else if (en) begin
                exec_memrw_pipe <= exec_memrw_pipe_d;
            end
        end
    end: gen_exec_memrw_pipe
    
    memrw #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH),
        .MEM_ADDR_WIDTH     (MEM_ADDR_WIDTH),
        .T_in               (exec_memrw_type),
        .T_out              (memrw_regwr_type)
    ) i_memrw (
        .in                 (exec_memrw_pipe),
        .dmem_addr          (dmem_addr),
        .dmem_rd_en         (dmem_rd_en),
        .dmem_wr_en         (dmem_wr_en),
        .dmem_wr_data       (dmem_wr_data),
        .dmem_wr_ben        (dmem_wr_ben),
        .dmem_rd_ack        (dmem_rd_ack),
        .dmem_rd_data       (dmem_rd_data),
        .dmem_wr_ack        (dmem_wr_ack),
        .pc_wr_hart_sel     (pc_wr_hart_sel),
        .pc_wr_en           (pc_wr_en),
        .pc_wr_data         (pc_wr_data),
        .out                (memrw_regwr_pipe_d)
    );
    
    if (1) begin: gen_memrw_regwr_pipe
        logic en;
        
        always_comb en =
            memrw_regwr_pipe_d.csr_wr_en | memrw_regwr_pipe_d.reg_wr_en |
            memrw_regwr_pipe.csr_wr_en | memrw_regwr_pipe.reg_wr_en;
        
        always_ff @(posedge clk) begin
            if (!rst) begin
                memrw_regwr_pipe <= '0;
            end else if (en) begin
                memrw_regwr_pipe <= memrw_regwr_pipe_d;
            end
        end
    end: gen_memrw_regwr_pipe
    
    regwr #(
        .NUM_HART           (NUM_HART),
        .REG_WIDTH          (REG_WIDTH),
        .T_in               (memrw_regwr_type)
    ) i_regwr (
        .in                 (memrw_regwr_pipe),
        .csr_wr_hart_sel    (csr_wr_hart_sel),
        .csr_wr_en          (csr_wr_en),
        .csr_wr_addr        (csr_wr_addr),
        .csr_wr_data        (csr_wr_data),
        .reg_wr_hart_sel    (reg_wr_hart_sel),
        .reg_wr_en          (reg_wr_en),
        .reg_wr_addr        (reg_wr_addr),
        .reg_wr_data        (reg_wr_data)
    );
endmodule

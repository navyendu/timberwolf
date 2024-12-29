module test_core;
    localparam int unsigned     REG_WIDTH = 32;
    localparam int unsigned     MEM_ADDR_WIDTH = 12;
    
    localparam int unsigned     BYTES_PER_ROW = REG_WIDTH / 8;
    localparam int unsigned     MEM_ROW_ADDR_WIDTH = MEM_ADDR_WIDTH - $clog2(BYTES_PER_ROW);
    
    logic                       clk;
    logic                       rst;
    
    logic                       imem_rd_en;
    logic [MEM_ADDR_WIDTH-1:0]  imem_rd_addr;
    
    logic                       imem_rd_ack;
    logic [REG_WIDTH-1:0]       imem_rd_data;
    
    logic [MEM_ADDR_WIDTH-1:0]  dmem_addr;
    logic                       dmem_rd_en;
    logic                       dmem_wr_en;
    logic [REG_WIDTH-1:0]       dmem_wr_data;
    logic [BYTES_PER_ROW-1:0]   dmem_wr_ben;
    
    logic                       dmem_rd_ack;
    logic [REG_WIDTH-1:0]       dmem_rd_data;
    
    logic                       dmem_wr_ack;
    
    initial begin
        clk = 1'b0;
        
        #10;
        
        forever begin
            clk = 1'b1; #5;
            clk = 1'b0; #5;
        end
    end
    
    initial begin
        rst <= 1'b0;
        
        repeat (2) @(posedge clk);
        
        rst <= 1'b1;
    end
    
    logic [MEM_ROW_ADDR_WIDTH-1:0] imem_row_addr;
    
    always_comb imem_row_addr = imem_rd_addr >> $clog2(BYTES_PER_ROW);
    mem #(
        .AWIDTH     (MEM_ROW_ADDR_WIDTH),
        .DWIDTH     (REG_WIDTH)
    ) imem0 (
        .clk        (clk),
        .wren       (1'b0),
        .wraddr     ('0),
        .wrdata     ('0),
        .wrben      ('0),
        .rdaddr     (imem_row_addr),
        .rddata     (imem_rd_data)
    );
    always_comb imem_rd_ack = imem_rd_en;
    
    logic [MEM_ROW_ADDR_WIDTH-1:0] dmem_row_addr;
    
    always_comb dmem_row_addr = dmem_addr >> $clog2(BYTES_PER_ROW);
    mem #(
        .AWIDTH     (MEM_ROW_ADDR_WIDTH),
        .DWIDTH     (REG_WIDTH)
    ) dmem0 (
        .clk        (clk),
        .wren       (dmem_wr_en),
        .wraddr     (dmem_row_addr),
        .wrdata     (dmem_wr_data),
        .wrben      (dmem_wr_ben),
        .rdaddr     (dmem_row_addr),
        .rddata     (dmem_rd_data)
    );
    always_comb dmem_rd_ack = dmem_rd_en;
    always_comb dmem_wr_ack = dmem_wr_en;
    
    initial begin
        int fd;
        int unsigned instr_ptr;
        
        string file = "/home/nav/Devel/timberwolf/build/astest_dis/test001.txt";
        
        $write("MEM_ROW_ADDR_WIDTH == %0d\n", MEM_ROW_ADDR_WIDTH);
        
        fd = $fopen(file, "r");
        if (!fd) begin
            $fatal("Failed to open dissassembly %0s", file);
        end
        
        instr_ptr = 0;
        while (!$feof(fd)) begin
            string str_line;
            string str_dummy;
            logic [31:0] instr;
            
            $fgets(str_line, fd);
            
            $sscanf(str_line, "%s %h", str_dummy, instr);
            
            $write("instr: %0h\n", instr);
            
            if (instr_ptr < $size(imem0.mem)) begin
                imem0.mem[instr_ptr] = instr;
            end
            
            instr_ptr += 1;
        end
        
        $fclose(fd);
        
        dmem0.mem[0] = 32'h01234567;
        // dmem0.mem[1] = 32'h89abcdef;
        // dmem0.mem[16] = 32'h76543210;
        // dmem0.mem[17] = 32'hfedcba98;
    end
    
    core #(
        .NUM_HART       (4),
        .REG_WIDTH      (REG_WIDTH),
        .MEM_ADDR_WIDTH (MEM_ADDR_WIDTH)
    ) core0 (
        .clk            (clk),
        .rst            (rst),
        .imem_rd_en     (imem_rd_en),
        .imem_rd_addr   (imem_rd_addr),      
        .imem_rd_ack    (imem_rd_ack),
        .imem_rd_data   (imem_rd_data),
        .dmem_addr      (dmem_addr),
        .dmem_rd_en     (dmem_rd_en),
        .dmem_wr_en     (dmem_wr_en),
        .dmem_wr_data   (dmem_wr_data),
        .dmem_wr_ben    (dmem_wr_ben),
        .dmem_rd_ack    (dmem_rd_ack),
        .dmem_rd_data   (dmem_rd_data),
        .dmem_wr_ack    (dmem_wr_ack)
    );
    
    // checker_core #(
    //     .NUM_HART       (4),
    //     .REG_WIDTH      (REG_WIDTH)
    // ) chk0 (
    //     .clk            (clk),
    //     .rst            (rst)
    // );
    
    initial begin
        repeat (100) @(posedge clk iff rst);
        
        $finish;
    end
endmodule

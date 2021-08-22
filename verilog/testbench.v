`timescale 1ns/1ps

module testbench;
    reg clk;
    reg rst;
    reg chenable;
    reg [31:0] r32;
    reg [7:0] r8[0:4000];
    integer i;
    integer j;
    integer cnt;
    integer fp;
    integer size;

    reg [31:0] data_1;
    reg [31:0] data_2;
    control ctrl (
	.clk(clk),
	.rst(rst),
	.enable(chenable)
    );

    initial begin
	clk = 0;
	forever #10 clk = ~clk;
    end

    initial begin
	cnt = 0;
	rst = 1;
        #100;
	
        fp = $fopen("raw.out", "rb");
        size = $fread(r8, fp);
	#1000;
	$fclose(fp);
/*	
	
	for (i = 0; i < size; i = i + 4) begin
		j = i / 4;
		r32 = { r8[i + 3], r8[i + 2], r8[i + 1], r8[i + 0] };
		if (i != 0) ctrl.m.bank[j] = r32;
		else ctrl.m.bank[0] = r32;
        end
*/
        for (i = 0; i < size; i = i + 4) begin
	        j = i / 4;
		r32 = { r8[i + 3], r8[i + 2], r8[i + 1], r8[i + 0] };
 	        { 
		      ctrl.instr_cache.memory_bank[i],
		      ctrl.instr_cache.memory_bank[i+1],
		      ctrl.instr_cache.memory_bank[i+2],
		      ctrl.instr_cache.memory_bank[i+3] 
		} = r32; 
        end

	for (i = 0; i < size; i = i + 4) begin
	    r32 = {
		ctrl.instr_cache.memory_bank[i],
		ctrl.instr_cache.memory_bank[i+1],
		ctrl.instr_cache.memory_bank[i+2],
		ctrl.instr_cache.memory_bank[i+3]
		};
	    $strobe("%x", r32);
	    #100;
	end

/*
        // mv $10, %gpr0
        { 
	  ctrl.instr_cache.memory_bank[0], 
	  ctrl.instr_cache.memory_bank[1], 
          ctrl.instr_cache.memory_bank[2],
          ctrl.instr_cache.memory_bank[3] 
	} = {3'd1, 2'd1, 3'd1,   4'd5, 4'd0, 1'd1, 4'd0, 11'd10}; // mv $10, %gpr0

	// sdw %gpr0, 4(%rzero)
	{ 
	  ctrl.instr_cache.memory_bank[4],
	  ctrl.instr_cache.memory_bank[5], 
	  ctrl.instr_cache.memory_bank[6],
	  ctrl.instr_cache.memory_bank[7]
	} = {3'd2, 2'd0, 3'd0,   4'd0, 4'd5, 1'd1, 15'd4};

	// mv $11, %gpr0
	{
          ctrl.instr_cache.memory_bank[8],
          ctrl.instr_cache.memory_bank[9],
          ctrl.instr_cache.memory_bank[10],
          ctrl.instr_cache.memory_bank[11]
	} = {3'd1, 2'd1, 3'd1,   4'd5, 4'd0, 1'd1, 4'd0, 11'd11}; 

        // sdw %gpr0, 8(%rzero)
        {
	  ctrl.instr_cache.memory_bank[12],
	  ctrl.instr_cache.memory_bank[13],
	  ctrl.instr_cache.memory_bank[14],
	  ctrl.instr_cache.memory_bank[15]
	} = {3'd2, 2'd0, 3'd0,   4'd0, 4'd5, 1'd1, 15'd8}; 

        // ldw 4(%rzero), %gpr1
        {
	  ctrl.instr_cache.memory_bank[16],
	  ctrl.instr_cache.memory_bank[17],
	  ctrl.instr_cache.memory_bank[18],
	  ctrl.instr_cache.memory_bank[19]
	} = {3'd2, 2'd0, 3'd3,   4'd6, 4'd0, 1'd1, 15'd4}; 

        // hlt
	{
	  ctrl.instr_cache.memory_bank[20],
	  ctrl.instr_cache.memory_bank[21],
	  ctrl.instr_cache.memory_bank[22],
	  ctrl.instr_cache.memory_bank[23]
        } = {3'd0, 2'd0, 3'd7,   24'd0}; 
*/
	chenable = 1;
	#100000;
	data_1 = {ctrl.data_cache.memory_bank[4], ctrl.data_cache.memory_bank[5], ctrl.data_cache.memory_bank[6], ctrl.data_cache.memory_bank[7]};
	data_2 = {ctrl.data_cache.memory_bank[8], ctrl.data_cache.memory_bank[9], ctrl.data_cache.memory_bank[10], ctrl.data_cache.memory_bank[11]};
	$strobe("mem @ 4:", data_1);
	$strobe("mem @ 8:", data_2);
	$strobe("gpr0: ", ctrl.r.regs[5]);
	$strobe("gpr1: ", ctrl.r.regs[6]);
	$finish;
    end

    always @ (posedge clk)
    begin
	if (cnt == 1) rst = 0;
	else cnt = cnt + 1;
    end
    initial begin
	$dumpfile("states.vcd");
	$dumpvars(1, clk);
	$dumpvars(1, ctrl.fsm_state);
	$dumpvars(1, ctrl.x1);
	$dumpvars(1, ctrl.x2);
	$dumpvars(1, ctrl.xd);
	$dumpvars(1, ctrl.y_data);
	$dumpvars(1, ctrl.dt.load_state);
	$dumpvars(1, ctrl.wen_regs);
	$dumpvars(1, ctrl.y);
	$dumpvars(1, ctrl.i1);
	$dumpvars(1, ctrl.i2);
        $dumpvars(1, ctrl.id);
	$dumpvars(1, ctrl.ld_done);
    end
endmodule

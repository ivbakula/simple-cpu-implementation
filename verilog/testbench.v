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
	.enable(chenable),
	.rx_line(rx_line),
        .tx_line(tx_line)
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
	end

	chenable = 1;
	@ (posedge ctrl.fsm_state[8])
	data_1 = {ctrl.data_cache.memory_bank[4], ctrl.data_cache.memory_bank[5], ctrl.data_cache.memory_bank[6], ctrl.data_cache.memory_bank[7]};
	data_2 = {ctrl.data_cache.memory_bank[8], ctrl.data_cache.memory_bank[9], ctrl.data_cache.memory_bank[10], ctrl.data_cache.memory_bank[11]};
	$strobe("mem @ 4:", data_1);
	$strobe("mem @ 8:", data_2);
	$strobe("gpr0: ", ctrl.r.regs[5]);
	$strobe("gpr1: ", ctrl.r.regs[6]);

	@ (negedge ctrl.io.transceiver.tx_busy);
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
	$dumpvars(1, ctrl.io_done);
	$dumpvars(1, ctrl.ld_done);
	$dumpvars(1, ctrl.tx_line);
	$dumpvars(1, ctrl.rx_line);
	$dumpvars(1, ctrl.io.transceiver.tx_busy);
    end
endmodule

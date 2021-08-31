`timescale 1ns/10ps

module testbench;
    reg clk_50;
    reg rst;
    wire rx_line;
    wire tx_line;

    control ctrl(
	.clk_50(clk_50), .rst_board(rst), .rx_line(rx_line), .tx_line(tx_line)
    );

    integer i;
    reg [31:0] r32;

    parameter c_CLOCK_PERIOD_NS = 20;
    initial begin
	clk_50 = 0;
	forever #(c_CLOCK_PERIOD_NS/2) clk_50 = !clk_50;
    end

    initial begin
	@(posedge clk_50)
	rst = 1;
	@(posedge clk_50)
	rst = 0;
	/*
	for(i = 0; i < 45; i = i + 4) begin
		r32 = {ctrl.instr_cache.memory_bank[i], 
		       ctrl.instr_cache.memory_bank[i+1],
		       ctrl.instr_cache.memory_bank[i+2],
		       ctrl.instr_cache.memory_bank[i+3]
		       };
		$strobe("0x%x", r32);
		#100;
	end
*/
	@(posedge ctrl.fsm_state[8])
	$finish;

    end

    always @ (posedge ctrl.fsm_state[6])
    begin
	$strobe("0x%x", ctrl.r.regs[14]);
    end
    initial begin
	$dumpfile("signals.vcd");
	$dumpvars(1, clk_50);
	$dumpvars(1, rst);
	$dumpvars(1, ctrl.fsm_state);
	$dumpvars(1, tx_line);
    end
endmodule

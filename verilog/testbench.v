`timescale 1ns/1ps

module testbench;
    reg clk;
    reg rst;
    reg chenable;
    reg [31:0] tmp;
    integer cnt;

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
//        ctrl.regs[0] = 12;
//	ctrl.regs[1] = 1123;
	ctrl.m.bank[0] = 32'b11000010000000010000000000001010; // MV $10, %r1
	ctrl.m.bank[1] = 32'b11000010000000100000000000000101; // MV $5, %r2
	ctrl.m.bank[2] = 32'b00000011001000010000000000000000; // ADD %r2, %r1
	ctrl.m.bank[3] = 32'b01000001000100000000000000010000; // STW %r1, &(16)
	ctrl.m.bank[4] = 32'b10000000000010000000000000010000; // LDW &(16), %r8;
	ctrl.m.bank[5] = 32'b00111111000000000000000000000000; // HLT
	#100;
	chenable = 1;
	#10000;
	tmp = ctrl.regs[1];
	$strobe(tmp);
	#100
	tmp = ctrl.regs[2];
	$strobe(tmp);
	#100;
	tmp = ctrl.m.bank[16];
	$strobe(tmp);
	#100;
	tmp = ctrl.regs[8];
	$strobe(tmp);
	#100000;
	$finish;
    end

    always @ (posedge clk)
    begin
	if (cnt == 1) rst = 0;
	else cnt = cnt + 1;
    end

endmodule

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
	for (i = 0; i < size; i = i + 4) begin
		j = i / 4;
		r32 = { r8[i + 3], r8[i + 2], r8[i + 1], r8[i + 0] };
		if (i != 0) ctrl.m.bank[j] = r32;
		else ctrl.m.bank[0] = r32;
        end

	chenable = 1;
	#100000;
	$finish;
    end

    always @ (posedge clk)
    begin
	if (cnt == 1) rst = 0;
	else cnt = cnt + 1;
    end
/*
    initial begin
	$dumpfile("states.vcd");
	$dumpvars(1, clk);
	$dumpvars(1, ctrl.state);
	$dumpvars(1, ctrl.write);
	$dumpvars(1, ctrl.read);
	$dumpvars(1, ctrl.data_r);
	$dumpvars(1, ctrl.y);
	$dumpvars(1, ctrl.mem_wen);
	$dumpvars(1, ctrl.data_w);
	$dumpvars(1, ctrl.address_bus);
	$dumpvars(1, ctrl.mem_rdy);
	$dumpvars(1, ctrl.dm.mem_addr);
	$dumpvars(1, ctrl.instr);

	#100000;
	$strobe("mem @ 1024: ", ctrl.m.bank[1024]);
    end
    */
endmodule

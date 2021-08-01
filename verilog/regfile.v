module regfile (
    input we,
    input rst,
    input [3:0] i1,
    input [3:0] i2,
    input [31:0] y,
    output reg [31:0] x1,
    output reg [31:0] x2
    );

    reg signed [31:0] regs [15:0];
    integer i;

    always @ ( * )
    begin
	if (rst) begin
	    for (i = 0; i < 16; i = i + 1) begin
		regs[i] = 0;
	    end
	end else if (we) regs[i2] = y; 
	else begin x1 = regs[i1]; x2 = regs[i2]; end
    end
endmodule



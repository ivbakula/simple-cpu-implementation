module alu (
    input en,
    input [5:0] opcode,
    input [31:0] x1,
    input [31:0] x2,
    output reg [31:0] y
    );

    localparam ADD = 6'b000100;
    localparam SUB = 6'b000101;
    localparam SHR = 6'b000110;
    localparam SHL = 6'b000111;
    localparam AND = 6'b001000;
    localparam OR  = 6'b001001;
    localparam XOR = 6'b001010;

    always @ ( * ) 
    begin
	if (en) begin
	    case (opcode)
		ADD: y = x2 + x1;
		SUB: y = x2 - x1;
		SHR: y = x2 >> x1;
		SHL: y = x2 << x1;
		AND: y = x2 & x1;
		OR:  y = x2 | x1;
		XOR: y = x2 ^ x1;
	    endcase
	end
    end
endmodule

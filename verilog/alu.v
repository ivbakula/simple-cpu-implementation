module alu (
    input en,
    input has_imm,
    input [4:0] opcode,
    input [31:0] x1,
    input [31:0] x2,
    input [15:0] imm,
    output reg [31:0] y
    );

    localparam ADD = 5'b00100;
    localparam SUB = 5'b00101;
    localparam SHR = 5'b00110;
    localparam SHL = 5'b00111;
    localparam AND = 5'b01000;
    localparam OR  = 5'b01001;
    localparam XOR = 5'b01010;
    localparam OUTW = 5'b01101;


    wire [31:0] src;
    assign src = (has_imm) ? imm : x1;

    always @ ( * ) 
    begin
	if (en) begin
	    case (opcode)
		ADD: y = x2 + src; 
		SUB: y = x2 - src;
		SHR: y = x2 >> src;
		SHL: y = x2 << src;
		AND: y = x2 & src;
		OR:  y = x2 | src;
		XOR: y = x2 ^ src;
	    endcase
	end
    end
endmodule



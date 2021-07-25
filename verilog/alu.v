`include "definitions.hv"

module alu (
    input enable,
    input rst,
    input [5:0]func,
    input [31:0] x1,
    input [31:0] x2,
    input [15:0] imm,
    output reg [31:0] y,
    output reg rdy
    );
    
    always @ (posedge rst) begin rdy = 0; end
    always @ (negedge enable) begin rdy = 0; end
    always @ (posedge enable)
    begin
	if (enable == 1) begin
	    case (func)
	        `ADD: begin y <= x1 + x2;  rdy <= 1; end
		`SUB: begin y <= x1 - x2;  rdy <= 1; end
		`SHR: begin y <= x1 >> x2; rdy <= 1; end
		`SHL: begin y <= x1 << x2; rdy <= 1; end
		`AND: begin y <= x1 & x2;  rdy <= 1; end
		`OR:  begin y <= x1 | x2;  rdy <= 1; end
		`XOR: begin y <= x1 ^ x2;  rdy <= 1; end
		`MV:  begin y <= imm; rdy <= 1; end
	    endcase
	end
    end
endmodule

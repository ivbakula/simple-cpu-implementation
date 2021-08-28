module alu (
    input en,
    input has_imm,
    input [2:0] opcode,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] xd,
    input [20:0] imm,
    output reg [31:0] y
    );

    localparam OPCODE_ADD = 3'b000;
    localparam OPCODE_ADDI = 3'b001;
    localparam OPCODE_SUB = 3'b010;
    localparam OPCODE_SHR = 3'b011;
    localparam OPCODE_SHL = 3'b100;
    localparam OPCODE_AND = 3'b101;
    localparam OPCODE_OR = 3'b110;
    localparam OPCODE_XOR = 3'b111;

    wire [31:0] src;
    assign src = (has_imm) ? imm : x1;

    always @ ( * ) 
    begin
	if (en) begin
	    case (opcode)
		OPCODE_ADD: y = xd + src; 
		OPCODE_ADDI: y = x1 + x2 + imm; 
		OPCODE_SUB: y = xd - src - imm;
		OPCODE_SHR: y = xd >> src;
		OPCODE_SHL: y = xd << src;
		OPCODE_AND: y = xd & src;
		OPCODE_OR:  y = xd | src;
		OPCODE_XOR: y = xd ^ src;
	    endcase
	end
    end
endmodule

module branch (
    input en,
    input reset,
    input [2:0] opcode,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] xd,
    input [20:0] imm,
    output reg [31:0] offset,
    output reg st_flag 
    );

    localparam OPCODE_BEQ = 3'h0;
    localparam OPCODE_BNE = 3'h1; 
    localparam OPCODE_BGT = 3'h2;
    localparam OPCODE_BLT = 3'h3;
    localparam OPCODE_BGE = 3'h4;
    localparam OPCODE_BLE = 3'h5;
    localparam OPCODE_BRN = 3'h6;

    wire [31:0]diff;
    assign diff = {11'b11111111111, imm};
    always @ ( * )
    begin
	if (reset) st_flag = 0;
	if (en) begin
	    offset = xd + diff;
	    $strobe("offset = xd + imm = %d + %d = %d", xd, imm, offset);
	    case (opcode)
		OPCODE_BGT: if (x1 > x2) st_flag = 1;
		OPCODE_BNE: if (x1 != x2) st_flag = 1;
		OPCODE_BEQ: if (x1 == x2) st_flag = 1;
		OPCODE_BGE: if (x1 >= x2) st_flag = 1;
	        OPCODE_BLT: if (x1 < x2) st_flag = 1;
	        OPCODE_BLE: if (x1 <= x2) st_flag = 1;
	        OPCODE_BRN: st_flag = 1;
	    endcase
	end 
    end
endmodule

module data_mov (
    input clk,
    input en,
    input [2:0] opcode,
    input [31:0] xs,
    input [31:0] xd,
    input [20:0] imm,
    input [31:0] i_data,
    output reg [31:0] i_addr,
    output reg [31:0] o_data,
    output reg [31:0] y,
    output reg [1:0] write_which,       // 2'b01 write regfile, 2'b10 write memory 
    output reg done
    );

    localparam OPCODE_SDW = 3'b000;
    localparam OPCODE_LDW = 3'b011;
    localparam OPCODE_OUT = 3'b110;

    localparam WRITE_REGFILE = 2'b01;
    localparam WRITE_MEMORY = 2'b10;
    localparam WRITE_NOTHING = 2'b00;

    reg [1:0]load_state;
    always @ ( * )
    begin
	if (en) 
	    case (opcode)
		OPCODE_SDW: begin
		    i_addr = xd + imm;
		    o_data = xs;
		    write_which = WRITE_MEMORY;
		    done = 1;
		end
		OPCODE_LDW: begin
		    case (load_state)
			2'b00: begin
			    done = 0;
			    i_addr = xs + imm;
			    load_state = 2'b01;
			end
			2'b01: begin
			    y = i_data;
			    write_which = WRITE_REGFILE;
			    load_state = 2'b10;
			end
			2'b10: done = 1;
		    endcase
		end
	    endcase
         else begin
	     i_addr = 32'bz;
             o_data = 32'bz;
	     write_which = WRITE_NOTHING;
	     load_state = 2'b00;
	     done = 0;
	 end
    end
endmodule

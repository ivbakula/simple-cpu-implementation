module data_mov (
    input en,
    input has_imm,
    input [4:0] opcode,
    input [15:0] imm,
    input [31:0] x,
    output reg [31:0] y,
    output reg [1:0] read,     // 2'b01 read memory, 2'b10 read regs, 2'b00 don't read
    output reg [1:0] write,    // 2'b01 write memory, 2'b10 write regs, 2'b00 don't read
    output reg [31:0] mem_addr
    );

    localparam LDW = 5'b00001;
    localparam STW = 5'b00010;
    localparam MV =  5'b00011;

    localparam REGS = 2'b10;
    localparam MEMORY = 2'b01; 
    localparam NOTHING = 2'b00;

    wire [31:0] src;
    assign src = (has_imm) ? imm : x;

    always @ ( * )
    begin
	if (en) 
	    case (opcode)
		MV: begin 
		    if (has_imm) read = NOTHING;
		    else read = REGS;
		    y = src;
		    write = REGS;
	        end
		STW: begin
		    read = REGS;
		    mem_addr = imm;
		    y = x;
		    write = MEMORY;
		end
		LDW: begin
		    read = MEMORY;
		    mem_addr = imm;
		    write = REGS;
		    y = x;
		end
	    endcase
         else begin
	     read = NOTHING;
	     write = NOTHING;
	 end
    end
endmodule



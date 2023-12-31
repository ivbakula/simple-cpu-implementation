module program_counter (
    input en,		// pc incrememnt enable 
    input [31:0] pc_curr,
    input st_flag,              // to branch (1) or not to branch (0)
    input [31:0] offset,           
    output reg [31:0] pc_nxt    // program counter 
    );
    always @ ( * )
    begin
	if (en) begin 
	    if (st_flag) pc_nxt = offset;
            else pc_nxt = pc_curr + 4;
	end
    end
endmodule

module decoder (
    input en,
    input [31:0] instr,
    output reg halt,
    output reg [2:0] func,
    output reg [1:0] type,
    output reg [2:0] opcode,
    output reg [3:0] rd,
    output reg [3:0] r1,
    output reg has_imm,
    output reg [3:0] r2,
    output reg [20:0] imm
    );

    localparam Type_A = 2'b00;
    localparam Type_B = 2'b01;
    localparam Type_C = 2'b10;
    always @ ( * )
    begin
//	if (en) begin
	    func = instr[31:29];
	    type = instr[28:27];
	    opcode = instr[26:24];

	    rd = instr[23:20];
	    r1 = instr[19:16];
	    has_imm = instr[15];
	    r2 = instr[14:11];

	    case (type)
		Type_A: begin 
		    if (instr[14]) imm = {6'b111111, instr[14:0]}; 
		    else imm = {6'b000000, instr[14:0]};
		end
 	        Type_B: begin 
		    if (instr[10]) imm = {10'b1111111111, instr[10:0]};
		    else imm = {10'b0000000000, instr[10:0]};
	        end
		default: imm = instr[20:0]; // TYPE_C
	    endcase

	    if (func == 3'b0) begin
		if (opcode == 3'b111) halt = 1;
	    end else
		halt = 0;
//	end
    end
endmodule

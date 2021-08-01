module decoder (
    input en,
    input [31:0] instr,
    output reg halt,
    output reg has_imm,
    output reg [1:0] func,
    output reg [4:0] opcode,
    output reg [3:0] rs,
    output reg [3:0] rd,
    output reg [15:0] imm
    );

    localparam HLT = 5'b01011;
    always @ ( * )
    begin
	if (en) begin
	    has_imm = instr[31];
	    func = instr [30:29]; 
	    opcode = instr [28:24];
	    rs = instr[23:20];
	    rd = instr[19:16];
	    imm = instr[15:0];
/*
	    $strobe("has_imm: %b", has_imm);
	    $strobe("func: %b", func);
	    $strobe("opcode: %b", opcode);
	    $strobe("rs: %b", rs);
	    $strobe("rd: %b", rd);
	    $strobe("imm: %b", imm);
*/
	    if (opcode == HLT)
		halt = 1;
	    else
		halt = 0;
	end
    end
endmodule

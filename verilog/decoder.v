module decoder (
    input en,
    input [31:0] instr,
    output reg halt,
    output reg [1:0] pfix,
    output reg [5:0] opcode,
    output reg [3:0] rs,
    output reg [3:0] rd,
    output reg [15:0] imm
    );

    localparam HLT = 6'b001011;
    always @ ( * )
    begin
	if (en) begin
	    pfix = instr [31:30]; 
	    opcode = instr [29:24];
	    rs = instr[23:20];
	    rd = instr[19:16];
	    imm = instr[15:0];
	    $strobe("pfix: %b", pfix);
	    $strobe("opcode: %b", opcode);
	    $strobe("rs: %b", rs);
	    $strobe("rd: %b", rd);
	    $strobe("imm: %b", imm);
	    if (opcode == HLT)
		halt = 1;
	    else
		halt = 0;
	end
    end
endmodule

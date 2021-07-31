module alu (
    input en,
    input [1:0] pfix,
    input [5:0] opcode,
    input [31:0] x1,
    input [31:0] x2,
    input [15:0] imm,
    output reg [31:0] y
    );

    localparam ADD = 6'b000100;
    localparam SUB = 6'b000101;
    localparam SHR = 6'b000110;
    localparam SHL = 6'b000111;
    localparam AND = 6'b001000;
    localparam OR  = 6'b001001;
    localparam XOR = 6'b001010;
    localparam OUTW = 6'b001101;


    wire [31:0] src;
    assign src = (pfix == 3) ? imm : x1;

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

module regs (
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

module data_mov (
    input en,
    input [1:0] pfix,
    input [5:0] opcode,
    input [15:0] imm,
    input [31:0] x1,
    output reg [31:0] y
    );

    localparam MV = 6'b000011;
    always @ ( * )
    begin
	if (en) 
	    case (pfix)
		2'b11: y = imm; 
		2'b00: y = x1;
	    endcase
    end
endmodule

module execute (
    input rst,
    input en,
    input [1:0] pfix,
    input [5:0] opcode,
    input [3:0] rs,
    input [3:0] rd,
    input [15:0] imm
    );

    reg low = 0;
    reg high = 1;

    wire alu_en;
    wire dm_en;

    wire [31:0] x1;
    wire [31:0] x2;
    wire [31:0] y;
    wire [31:0] y_alu;
    wire [31:0] y_dm;

    wire we;     // write enable registers

    assign alu_en = (opcode != 6'b000011) ? en : low; // it will be high if enable is high and condition is true
    assign dm_en = (opcode == 6'b000011) ? en : low; // it will be high if enale is high and condition is true

    assign we = (alu_en | dm_en) ? high : low;
    assign y = (alu_en) ? y_alu : ((dm_en) ? y_dm : 32'bz);

    alu a (
	.en(alu_en),
	.pfix(pfix),
	.opcode(opcode),
	.imm(imm),
        .x1(x1),
	.x2(x2),
	.y(y_alu)
    );

    regs r (
	.we(we),
	.rst(rst),
	.i1(rs),
        .i2(rd),
	.y(y),
	.x1(x1),
	.x2(x2)
    );

    data_mov dm (
	.en(dm_en),
	.pfix(pfix),
	.opcode(opcode),
	.imm(imm),
	.x1(x1),
	.y(y_dm)
    );
endmodule

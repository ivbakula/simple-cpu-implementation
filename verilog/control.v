module control (
    input clk,
    input rst,
    input enable
    );

    wire [5:0]state;

    // program counter 
    wire [31:0] pc;
    wire [31:0] instr;

    // memory module
    wire [31:0] address_bus;
    wire [31:0] data_r;
    wire [31:0] data_w;
    wire mem_rdy;

    // instruction fields
    wire halt;
    wire [1:0] pfix;
    wire [5:0] opcode;
    wire [3:0] rs;
    wire [3:0] rd;
    wire [15:0] imm;

    // alu operands
    wire [31:0] x1;
    wire [31:0] x2;
    wire [31:0] y;

    // control signals (depend on current state)
    wire en_i;		// enable program counter (increment pc)
    wire decod_en;      // enable instruction decoder
    wire alu_en;        // alu enable
    wire mem_ren;	// memory read enable 
    wire mem_wen;	// memory write enable
    wire wen_regs;	// write enable registers
    
    assign mem_ren = state[1];
    assign decod_en = state[2];
    assign alu_en = state[3];
    assign wen_regs = state[3];
    assign en_i = state[4];

    assign address_bus = pc;
    assign instr = data_r;

    program_counter p (
	.rst(rst),
	.en_inc(en_i),
	.pc(pc)
    );

    memory m (
	.rst(rst),
	.clk(clk),
	.we(mem_wen),
	.re(mem_ren),
	.address(address_bus),
	.data_w(data_w),
	.data_r(data_r),
	.rdy(mem_rdy)
    );

    execute exe (
	.rst(rst),
	.en(alu_en),
	.pfix(pfix),
	.opcode(opcode),
	.rs(rs),
	.rd(rd),
	.imm(imm)
    );

    decoder d (
	.en(decod_en),
	.instr(instr),
	.halt(halt),
	.pfix(pfix),
	.opcode(opcode),
	.rs(rs),
	.rd(rd),
	.imm(imm)
    );

    moore_fsm fsm (
	.clk(clk),
	.rst(rst),
	.en(enable),
	.state(state),
	.mem_rdy(mem_rdy),
	.halt(halt)
    );
endmodule

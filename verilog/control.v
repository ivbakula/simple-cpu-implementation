module control (
    input clk,
    input rst,
    input enable
    );

    localparam REGS = 2'b10;
    localparam MEMORY = 2'b01;

    reg high = 1;
    reg low = 0;

    wire [8:0]state;

    // program counter 
    wire [31:0] pc;
    wire [31:0] instr;

    // branch module
    wire [15:0] jmp_addr; 
    wire st_flag;

    // memory module
    wire [31:0] address_bus;
    wire [31:0] data_r;
    wire [31:0] data_w;
    wire mem_rdy;

    // instruction fields
    wire halt;
    wire has_imm;
    wire [1:0] func;
    wire [4:0] opcode;
    wire [3:0] rs;
    wire [3:0] rd;
    wire [15:0] imm;

    // alu operands and data mov operands 
    wire [31:0] x1;
    wire [31:0] x2;
    wire [31:0] y_alu;

    wire [31:0] y_mov;
    wire [31:0] x;
    wire [1:0] read;
    wire [1:0] write;
    wire [31:0] mem_addr;
    wire [31:0] rsp;

    wire [31:0] y;

    // control signals (depend on current state)
    wire mem_ren;	// memory read enable 
    wire decod_en;      // enable instruction decoder
    wire alu_en;        // alu enable
    wire mov_en;        // data mov enable
    wire en_brnch;      // enable branch block
    wire en_io;         // enable IO block 
    wire en_pc;		// enable program counter (increment pc)
    wire fetch;

    wire wen_regs;	// write enable registers
    wire mem_wen;	// memory write enable

    assign fetch = state[1];
    assign decod_en = state[2];
    assign alu_en = state[3];
    assign mov_en = state[4];
    assign en_brnch = state[5];
    assign en_io = state[6];
    assign en_pc = state[7];

    assign wen_regs = (alu_en) ? high : ((write == REGS) ? high : low); // state[3] -alu state[4] - data mov
    assign y = (alu_en) ? y_alu : ((mov_en) ? y_mov : 32'bz);
    assign mem_ren = (fetch) ? high : ((read == MEMORY) ? high : low);
    assign mem_wen = (write == MEMORY) ? high : low; 

    assign x = (read == MEMORY) ? data_r : x1;
    assign {instr, x} = (read != MEMORY) ? {data_r, 32'bz} : {32'bz, data_r};
    assign address_bus = (fetch) ? pc : mem_addr;
    assign data_w = (write == MEMORY) ? y : 32'bz;


    program_counter p (
	.rst(rst),
	.en_inc(en_pc),
	.st_flag(st_flag),
	.jmp_addr(jmp_addr),
	.pc(pc)
    );

    input_output io (
	.en(en_io),
	.opcode(opcode),
	.x1(x1)
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

    branch b (
	.en(en_brnch),
	.pc(en_pc),
	.opcode(opcode),
	.x1(x1),
	.x2(x2),
	.imm(imm),
	.jmp_addr(jmp_addr),
	.st_flag(st_flag)
    );

    alu a (
	.en(alu_en),
	.has_imm(has_imm),
	.opcode(opcode),
	.x1(x1),
	.x2(x2),
	.imm(imm),
	.y(y_alu)
    );

    regfile r (
	.we(wen_regs),
	.rst(rst),
	.i1(rs),
	.i2(rd),
	.y(y),
	.x1(x1),
	.x2(x2),
	.rsp(rsp)
    );

    data_mov dm (
	.en(mov_en),
	.has_imm(has_imm),
	.opcode(opcode),
	.imm(imm),
	.x(x),
	.y(y_mov),
	.read(read),
	.write(write),
	.mem_addr(mem_addr),
	.rsp(rsp)
    );

    decoder d (
	.en(decod_en),
	.instr(instr),
	.halt(halt),
	.has_imm(has_imm),
	.func(func),
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
	.func(func),
	.mem_rdy(mem_rdy),
	.halt(halt)
    );
endmodule

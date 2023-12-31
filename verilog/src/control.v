module control (
    input clk_50,
    input rst_board,
//    input enable,

    input rx_line,
    output tx_line
    );
 
    // load firmware helpers
    integer fp;
    integer size;
    integer i;
    integer j;
    reg [7:0]r8;
    reg [31:0]r32[11:0];

    reg low = 0;
    reg high = 1;
    reg [31:0] nothing = 32'bz;

    // state machine
    wire [8:0] fsm_state;

    // program counter
    reg [3:0] pc_index = 4'b0001;
    wire [31:0] pc;
    wire [31:0] pc_next;

    // decoder ports
    wire [31:0] instr;
    wire halt;
    wire has_imm;
    wire [2:0] func;
    wire [1:0] type;
    wire [2:0] opcode;
    wire [3:0] rd;
    wire [20:0] imm;

    // alu ports
    wire [31:0] y_alu;

    // data module ports
    localparam WRITE_REGFILE = 2'b01;
    localparam WRITE_MEMORY = 2'b10;
    wire [1:0]write_which;
    wire [31:0] y_data;
    wire ld_done;
    wire io_done;

    // branch module ports
    wire [31:0] offset;
    wire st_flag;

    // regfile ports
    wire wen_regs;
    wire [3:0] i1;       // first source register index
    wire [3:0] i2;       // second source register index
    wire [3:0] id;       // destination register index 
    wire [31:0] y;       // y data write line 
    wire [31:0] x1;      // first source register data
    wire [31:0] x2;      // second source register data
    wire [31:0] xd;      // destination register data

    // data cache ports
    wire [31:0] i_addr;
    wire [31:0] o_data;
    wire [31:0] i_data;
    wire i_write; 

    assign wen_regs = (fsm_state[3] | fsm_state[7]) ? high : (
	(write_which == WRITE_REGFILE) ? high : low
    );
    assign y = (fsm_state[3]) ? y_alu : (
	(fsm_state[7]) ? pc_next : (
	    (write_which == WRITE_REGFILE) ? y_data : 32'bz
        )
    );
    assign id = (fsm_state[7]) ? pc_index : rd;
    assign i_write = (write_which == WRITE_MEMORY) ? high : low;

    decoder d (
	.en(fsm_state[2]), .instr(instr), .halt(halt),
	.func(func),       .type(type),   .opcode(opcode),
	.rd(rd),           .r1(i1),       .r2(i2),
	.has_imm(has_imm), .imm(imm)
    );

    data_mov dt (
	.en(fsm_state[4]), .opcode(opcode), .xs(x1),
	.xd(xd),           .imm(imm),       .i_addr(i_addr),
	.o_data(o_data),   .i_data(i_data), .write_which(write_which),
	.y(y_data),        .clk(clk_50),       .done(ld_done)
    );

    alu a (
	.en(fsm_state[3]), .has_imm(has_imm), .opcode(opcode),
        .x1(x1),           .x2(x2),           .xd(xd), 
	.imm(imm),         .y(y_alu)
    );

    branch brn (
	.en(fsm_state[5]), .reset(fsm_state[1]), .opcode(opcode), .x1(x1), 
	.x2(x2),           .xd(xd),         .imm(imm),       
	.offset(offset),   .st_flag(st_flag)
    );

    input_output io (
	.clk(clk_50), .en(fsm_state[6]), .xd(xd), .rdy(io_done), .rxd_pin(rx_line), .txd_pin(tx_line)
    );

    program_counter p (
	.en(fsm_state[7]), .pc_curr(pc), .st_flag(st_flag), 
	.pc_nxt(pc_next),  .offset(offset)
    );

    moore_fsm fsm (
	.rst(rst_board),   .clk(clk_50),   
	.func(func), .halt(halt), .state(fsm_state),
	.ld_done(ld_done), .io_done(io_done)
    );

    regfile r (
	.we(wen_regs), .clk(clk_50), .rst(rst_board), 
        .i1(i1),       .i2(i2),   .id(id), 
        .y(y),         .x1(x1),   .x2(x2),
        .xd(xd),       .pc(pc)
    );

    bram #( .TYPE(2)) data_cache (
	.clk(clk_50),    /*.rst(rst_board),*/   .i_addr(i_addr), .i_write(i_write),
	.i_data(o_data), .o_data(i_data)
    );

    bram #( .TYPE(1)) instr_cache (
	.clk(clk_50),     /* .rst(rst_board),*/   .i_addr(pc),   .i_write(low),
	.i_data(nothing), .o_data(instr)
    );
endmodule

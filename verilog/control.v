module control (
    input clk,
    input rst,
    input enable
    );

    integer i;
    reg [31:0]cntr;
    reg [31:0] regs[15:0]; // 16 GP registers

    // program counter
    reg [31:0] instr;
    reg [31:0] pc;        // instruction pointer 
    reg [1:0] pc_control; // msb - increment pc and fetch new; lsb just fetch_new

    
    // alu signals
    reg [31:0] x1;        // first operand 
    reg [31:0] x2;        // second operand
    wire [31:0] y;        // result 
    reg alu_enable;
    wire alu_rdy;

    // memory signals
    reg r_enable;    // read enable (RAM)
    reg w_enable;    // write enable (RAM)
    reg [31:0]address_bus;
    reg [31:0]word_in;     // write word to memory
    wire [31:0]word_out;    // word read from memory
    wire mem_rdy;

    // instruction fields
    wire [1:0] pfix = instr[31:30];
    wire [5:0] opcode = instr[29:24];
    wire [3:0] rs = instr[23:20];
    wire [3:0] rd = instr[19:16];
    wire [15:0] imm = instr[15:0];

    always @ (posedge rst)
    begin
      for (i = 0; i < 16; i = i + 1) begin
           regs[i] = 0;
      end
      cntr = 0;
      pc = 0;
      pc_control = 1;
    end

    always @ (posedge mem_rdy)
    begin
	if (enable == 1) begin
	    if (pc_control != 0) begin 
		instr <= word_out; 
		r_enable <= 0; 
	    end else begin
	        if (r_enable == 1) begin
		    regs[rd] <= word_out;
		    r_enable <= 0;
	        end else w_enable <= 0;
                pc_control <= 2;    
	    end
	end
    end

    always @ (posedge clk)
    begin
	if ((enable & mem_rdy) == 1) begin
	    case (pc_control)
	        2'b01: begin
		     address_bus = pc;
		     r_enable = 1;
	        end
	        2'b10: begin
		     pc = pc + 1;
		     address_bus = pc;
		     r_enable = 1;
	        end
	    endcase
        end
    end

    always @ (instr)
    begin
	if (enable == 1) begin
             pc_control = 0;
	     case (pfix)
		 2'b00: begin 
		      alu_enable <= 1; 
		 end
		 2'b01: begin
		     word_in <= regs[rs];
		     address_bus <= imm;
		     w_enable <= 1;
		 end
		 2'b10: begin
		     address_bus <= imm;
		     r_enable <= 1;
		 end
		 2'b11: begin
		     alu_enable <= 1;
		 end
	     endcase 
        end
    end

    always @ (posedge alu_rdy)
    begin
	if (opcode != 6'b111111) begin
	    regs[rd] = y; 
	    alu_enable = 0;
            pc_control = 2;
	end
    end
    
    alu a (
	.func(opcode),
	.enable(alu_enable),
	.x1(regs[rs]),
	.x2(regs[rd]),
	.imm(imm),
	.y(y),
	.rdy(alu_rdy)
    );

    memory m (
	.clk(clk),
	.rst(rst),
	.w_enable(w_enable),
	.r_enable(r_enable),
	.address(address_bus),
	.word_in(word_in),
	.word_out(word_out),
	.rdy(mem_rdy)
    );

endmodule

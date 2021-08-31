module bram #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 8, DEPTH = 2250, TYPE = 0) (
    input wire clk,
    input wire [ADDR_WIDTH-1:0] i_addr,
    input wire i_write,
    input wire [ADDR_WIDTH-1:0] i_data,
    output reg [ADDR_WIDTH-1:0] o_data
    );

    reg [DATA_WIDTH-1:0] memory_bank[0:DEPTH-1];

    initial begin
	if (TYPE == 1)
	    $readmemh("firmware_text.hex", memory_bank);
	else if (TYPE == 2)
	    $readmemh("firmware_data.hex", memory_bank);
    end

    always @ ( negedge clk )
    begin
	if (i_write) begin
	    {memory_bank[i_addr], memory_bank[i_addr+1], memory_bank[i_addr+2], memory_bank[i_addr+3]} <= i_data;
	end else begin
	    o_data <= {memory_bank[i_addr], memory_bank[i_addr+1], memory_bank[i_addr+2], memory_bank[i_addr+3]};
	end
    end
endmodule

module regfile (
    input we,
    input clk,
    input rst,
    input [3:0] i1,
    input [3:0] i2,
    input [3:0] id,
    input [31:0] y,
    output reg [31:0] x1,
    output reg [31:0] x2,
    output reg [31:0] xd,
    output [31:0] pc
    );

    reg signed [31:0] regs [15:0];
    integer i;

    assign pc = regs[1];

    always @ ( negedge clk )
    begin
	if (rst) begin
	    for (i = 0; i < 16; i = i + 1) 
		regs[i] = 0;
	end else if (we) begin
	    if (id) regs[id] <= y;
	end
    end

    always @ ( * )
    begin
       if(!rst) begin 
	    x1 = regs[i1]; 
	    x2 = regs[i2]; 
	    xd = regs[id]; 
       end
    end
endmodule

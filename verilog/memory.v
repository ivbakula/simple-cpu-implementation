module memory (
    input clk,			// clock 
    input rst,			// reset 
    input w_enable,	        // write enable 
    input r_enable,		// read enable
    input [31:0]address,		// memory address
    input [31:0]word_in,		// word to write to memory location designated by address
    output reg [31:0]word_out,	// word to read from location designated by address
    output reg rdy
    );

    reg [31:0] bank [16383:0];	// 64K memory bank (14K of words) 
    integer i;

    always @ (posedge clk) begin if (rdy == 0) rdy <= 1; end
    always @ (negedge clk)
    begin
	if (rst == 1) begin
	    rdy = 0;
	    for (i = 0; i < 16383; i = i + 1) begin
		bank[i] = 0;
	    end
	end else if (w_enable == 1) begin
	    rdy = 0;
	    bank[address] = word_in;
	end else if (r_enable == 1) begin
	    rdy = 0;
	    word_out = bank[address];
//	    $strobe("bank[%d]: ", address, bank[address], word_out);
	end 
    end
endmodule

module memory (
    input rst,
    input clk,
    input we,
    input re,

    input [31:0] address,
    input [31:0] data_w,
    output reg [31:0] data_r,
    output reg rdy
    );
    integer i;
    reg [31:0] bank [4028:0];

    always @ ( posedge re ) begin rdy <= 0; end
    always @ ( posedge we ) begin rdy <= 0; end

    always @ ( posedge rst )
    begin
	if (rst) begin 
	   for (i = 0; i < 4028; i = i + 1) 
	       bank[i] = 0;
	   rdy = 1;
        end
    end

    always @ ( negedge clk )
    begin
	if (!rst) begin
	    if (re) begin data_r <= bank[address]; rdy <= 1; end
	    else if (we) begin bank[address] <= data_w; rdy <= 1; end
	end
    end
endmodule

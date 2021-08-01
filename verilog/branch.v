module branch (
    input en,
    input pc,
    input [4:0]opcode,
    input [31:0]x1,
    input [31:0]x2,
    input [15:0]imm,
    output [15:0]jmp_addr,
    output reg st_flag 
    );

    localparam BGT = 5'b01101;
    localparam BEQ = 5'b01110;
    localparam BGE = 5'b01111;
    localparam BLT = 5'b10000;
    localparam BLE = 5'b10001;
    localparam BRN = 5'b10010;

    reg [15:0]addr;
    assign jmp_addr = addr;

    always @ ( * )
    begin
	if (en) begin
	    addr = imm;
	    case (opcode)
		BGT: if (x1 > x2) st_flag = 1;
		BEQ: if (x1 == x2) st_flag = 1;
		BGE: if (x1 >= x2) st_flag = 1;
	        BLT: if (x1 < x2) st_flag = 1;
	        BLE: if (x1 <= x2) st_flag = 1;
	        BRN: st_flag = 1;
	    endcase
	end else if (!pc) st_flag = 0;
    end
endmodule

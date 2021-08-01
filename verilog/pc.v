module program_counter (
    input rst,
    input en_inc,		// pc incrememnt enable 
    input st_flag,              // to branch (1) or not to branch (0)
    input [15:0]jmp_addr,           
    output reg [31:0] pc	// program counter 
    );
    always @ ( * )
    begin
        if (rst) pc = 0;
	else if (en_inc) begin 
	    if (st_flag) pc = jmp_addr;
            else pc = pc + 1;
	end
    end
endmodule

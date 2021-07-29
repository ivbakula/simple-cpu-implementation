module program_counter (
    input rst,
    input en_inc,		// pc incrememnt enable 
    output reg [31:0] pc	// program counter 
    );
    always @ ( * )
    begin
        if (rst) pc = 0;
	else if (en_inc) pc = pc + 1;
    end
endmodule

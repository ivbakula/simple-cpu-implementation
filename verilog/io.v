module input_output (
    input en,
    input [4:0] opcode,
    input [31:0] x1
    );

    localparam OUTW = 5'b01100;
    always @ ( * )
    begin
	if (en) 
	    case (opcode) 
		OUTW: $strobe(x1);
	    endcase
    end
endmodule

module moore_fsm (
    // "outside world" control signals
    input rst,	// reset
    input clk,  // clock
    input en,   // enable

    // control unit control signals
    input mem_rdy,
    input halt,

    output [5:0] state
    );

    localparam STATE_Initial = 6'b000001;
    localparam STATE_Fetch =   6'b000010; 
    localparam STATE_Decode =  6'b000100;
    localparam STATE_Alu =     6'b001000;
    localparam STATE_IncPC =   6'b010000;
    localparam STATE_Halt =    6'b100000;

    reg [5:0] current_state;
    reg [5:0] next_state;

    assign state = current_state;

    always @ ( posedge clk )
    begin
	if (rst) next_state <= STATE_Initial;
	else  current_state <= next_state;
    end

    always @ ( * )
    begin
	case (current_state)
	    STATE_Initial: if (en) next_state = STATE_Fetch;

	    STATE_Fetch: if (mem_rdy) next_state = STATE_Decode;

	    STATE_Decode: begin
		if (halt) next_state = STATE_Halt;
		else next_state = STATE_Alu;
	    end

	    STATE_Alu: next_state = STATE_IncPC;
	    STATE_IncPC: next_state = STATE_Fetch;
	endcase
    end

endmodule

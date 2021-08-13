module moore_fsm (
    // "outside world" control signals
    input rst,	// reset
    input clk,  // clock
    input en,   // enable

    // control unit control signals
    input ld_done,
    input [2:0]func,
    input halt,

    output [8:0] state
    );

    localparam STATE_Initial = 9'b000000001;  // 0
    localparam STATE_Fetch =   9'b000000010;  // 1
    localparam STATE_Decode =  9'b000000100;  // 2
    localparam STATE_Alu =     9'b000001000;  // 3
    localparam STATE_DataMov = 9'b000010000;  // 4
    localparam STATE_Branch =  9'b000100000;  // 5
    localparam STATE_Io =      9'b001000000;  // 6
    localparam STATE_IncPC =   9'b010000000;  // 7
    localparam STATE_Halt =    9'b100000000;  // 8

    localparam FUNC_BLOCK_ALU = 3'b001;
    localparam FUNC_BLOCK_DATA = 3'b010;
    localparam FUNC_BLOCK_BRANCH = 3'b011;
    localparam FUNC_BLOCK_SPEC   = 3'b000;

    reg [8:0] current_state;
    reg [8:0] next_state;

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

	    STATE_Fetch: next_state = STATE_Decode;

	    STATE_Decode: begin
		if (halt) next_state = STATE_Halt;
		else case (func)
		         FUNC_BLOCK_ALU: next_state = STATE_Alu;
		         FUNC_BLOCK_DATA: next_state = STATE_DataMov;
			 FUNC_BLOCK_BRANCH: next_state = STATE_Branch;
	             endcase
	    end

	    STATE_Alu: next_state = STATE_IncPC;
	    STATE_DataMov: if(ld_done) next_state = STATE_IncPC;
	    STATE_Io: next_state = STATE_IncPC;
	    STATE_Branch: next_state = STATE_IncPC;
	    STATE_IncPC: next_state = STATE_Fetch;
	endcase
    end
endmodule

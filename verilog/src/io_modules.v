// uart reciever: 
//
// default baud: 115200, 
// transfer size: 8 bits 
// parity bits: no parity bits
// flow control: none
//

module uart_rx #(parameter BAUD = 115200) (
    input clk,
    input i_rx_line,
    output reg [7:0] o_rx_data,
    output reg rdy
    );

    localparam CLKS_PER_BIT = 434;
    localparam STATE_IDLE = 4'b0001; 
    localparam STATE_START = 4'b0010;
    localparam STATE_TRANSFER = 4'b0100;
    localparam STATE_STOP = 4'b1000;

    reg [3:0] state = STATE_IDLE;
    reg [2:0] r_index = 3'd0;
    reg [15:0] clk_count = 16'd0;
    reg [7:0] data = 8'd0;
    always @ ( posedge clk )
    begin
	case (state)
	    STATE_IDLE: begin
	        rdy <= 0;
	        clk_count <= 0;
	        r_index <= 0;
	        o_rx_data <= 8'd0;
		data <= 8'd0;

	        if (!i_rx_line)
		    state <= STATE_START;
	        else
		    state <= STATE_IDLE;
	    end // STATE_IDLE

	    STATE_START: begin
		r_index <= 0;
		if (clk_count == (CLKS_PER_BIT - 1)/2) begin
		    if (!i_rx_line) begin
			clk_count <= 0;
			state <= STATE_TRANSFER;
		    end else begin
			clk_count <= 0;
		        state <= STATE_IDLE;
		    end
		end else begin
		    clk_count <= clk_count + 1;
		    state <= STATE_START;
		end
	    end // STATE_START

	    STATE_TRANSFER: begin
		data[r_index] <= i_rx_line;
		if (clk_count < CLKS_PER_BIT - 1) begin
		    clk_count <= clk_count + 1;
		    state <= STATE_TRANSFER;
		end else begin
		    if (r_index < 7) begin
			r_index <= r_index + 1;
			clk_count <= 16'd0;
			state <= STATE_TRANSFER;
		    end else begin
		        clk_count <= 16'd0;
			state <= STATE_STOP;
		    end
		end
	    end // STATE_TRANSFER

	    STATE_STOP: begin
		o_rx_data <= data;
		if (clk_count < (CLKS_PER_BIT - 1)/2) begin
		    clk_count <= clk_count + 1;
		    state <= STATE_STOP;
		end else begin
		    rdy <= 1;
		    if (clk_count < CLKS_PER_BIT - 1) begin
			clk_count <= clk_count + 1;
			state <= STATE_STOP;
		    end else begin
			clk_count <= 0;
			state <= STATE_IDLE;
		    end
		end
	    end // STATE_STOP
	endcase 
    end
endmodule

// uart transmitter: 
//
// default baud: 115200, 
// transfer size: 8 bits 
// parity bits: no parity bits
// flow control: none
//

module uart_tx #(parameter BAUD = 115200) (
    input clk,
    input [7:0] i_tx_byte,
    input i_tx_drive,
    output reg o_tx_busy,
    output reg o_tx_line
    );

    localparam CLKS_PER_BIT = 434;

    localparam STATE_IDLE     = 4'b0001;
    localparam STATE_START    = 4'b0010;
    localparam STATE_TRANSFER = 4'b0100;
    localparam STATE_STOP     = 4'b1000;

    reg [3:0] state   = STATE_IDLE;    
    reg [2:0] r_index = 3'd0;   // index of current bit to transfer over the line
    reg [7:0] r_tx_data;
    reg [15:0] clk_count = 16'd0;

    always @ (posedge clk)
    begin
        case (state)
	    STATE_IDLE: begin
	        o_tx_line <= 1'b1;
		r_index   <= 3'b000;
		clk_count <= 16'd0;
		
		if (i_tx_drive) begin
		    r_tx_data <= i_tx_byte; 
		    state <= STATE_START;
		    o_tx_busy <= 1;
		end else begin
		    state <= STATE_IDLE;
		    r_tx_data <= 8'd0;
		    o_tx_busy <= 0;
		end

	    end // STATE_IDLE

	    STATE_START: begin
               o_tx_line <= 1'b0; 
	       if (clk_count < CLKS_PER_BIT - 1) begin
	           clk_count <= clk_count + 1;	   
		   state <= STATE_START;
	       end else begin
	           clk_count <= 0;
		   state <= STATE_TRANSFER;
	       end
	    end // STATE_START

	    STATE_TRANSFER: begin
	        o_tx_line <= r_tx_data[r_index];
		if (clk_count < CLKS_PER_BIT - 1) begin
		    clk_count <= clk_count + 1;
		    state <= STATE_TRANSFER;
		end else begin
		    clk_count <= 0;
		    if (r_index < 7) begin
			r_index <= r_index + 1;
			state <= STATE_TRANSFER;
		    end else begin
			r_index <= 3'd0;
			state <= STATE_STOP;
		    end
		end
	    end // STATE_TRANSFER

	    STATE_STOP: begin
		o_tx_line <= 1'b1;
		if (clk_count < CLKS_PER_BIT - 1) begin
		    clk_count <= clk_count + 1;
		    state <= STATE_STOP;
		end else begin
		    clk_count <= 0;
		    state <= STATE_IDLE;
		end
	    end // STATE_STOP
	endcase
    end
endmodule

module uart_transceiver (
   input clk,
   input en,
   input [7:0] data_send,
   output [7:0] data_recieve,
   output reg rdy,

   input rxd,  // outside world (pin on fpga)
   output txd  // outside world (pin on fpga)
   );

   localparam STATE_IDLE  = 3'b001;
   localparam STATE_START = 3'b010;
   localparam STATE_DONE  = 3'b100;

   reg tx_start;
   wire tx_busy;
   reg [2:0] state = STATE_IDLE; 
   reg [1:0] counter = 2'b00;
   reg [7:0] send_buffer;

   always @ ( posedge clk )
   begin
       case (state)
	   STATE_IDLE: begin
	       rdy <= 0;
	       counter <= 0;
	       send_buffer <= 0;
	       if (en) begin
		   state <= STATE_START;
	       end else begin
		   state <= STATE_IDLE;
	       end
	   end // STATE_IDLE

           STATE_START: begin
	       send_buffer <= data_send; 
	       tx_start <= 1;
	       if (counter < 1) begin
		   counter <= counter + 1;
		   state <= STATE_START;
	       end else begin
		   counter <= 0;
		   state <= STATE_DONE;
	       end
	   end

	   STATE_DONE: begin
	       tx_start <= 0;
	       if (!tx_busy) begin
		   rdy <= 1;
		   if (counter < 1) counter <= counter + 1;
		   else state <= STATE_IDLE;
	       end else 
		   state <= STATE_DONE;
	   end // STATE_DONE
       endcase
   end
   uart_rx rx(.clk(clk), .i_rx_line(rxd), .o_rx_data(data_recieve), .rdy(rx_rdy));
   uart_tx tx(.clk(clk), .i_tx_byte(send_buffer), .i_tx_drive(tx_start), .o_tx_busy(tx_busy), .o_tx_line(txd));
endmodule

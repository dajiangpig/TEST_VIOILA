`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:22:16 08/07/2020
// Design Name:   vioila_test
// Module Name:   F:/rosenewboardFPGA/TEST_VIOILA/test.v
// Project Name:  TEST_VIOILA
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vioila_test
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test;

	// Inputs
	reg CLK_50M;
	reg CLK_25M;
	reg rx;
   reg [7:0] echo;
	// Outputs
	wire tx;
   wire CLK_BUS;
	wire CLK_UART;
	wire rst;
	wire [7:0] rx_byte;
	wire [7:0] tx_byte_bus;
	wire transmit_bus;
	// Instantiate the Unit Under Test (UUT)
	vioila_test uut (
		.CLK_50M(CLK_50M), 
		.rx(rx), 
		.tx(tx),
		.CLK_BUS(CLK_BUS),
		.CLK_UART(CLK_UART),
		.rst(rst),
	   .rx_byte(rx_byte),
      .tx_byte_bus(tx_byte_bus),
      .transmit_bus(transmit_bus)	 
	);

	initial begin
		// Initialize Inputs
		CLK_50M = 0;
		rx = 1;
		CLK_25M = 0;

		// Wait 100 ns for global reset to finish
		#100;
       rx = 1;
		// Add stimulus here

	end
	
	
	always #10 CLK_50M = ~CLK_50M; 
	always #20 CLK_25M=~CLK_25M; 
	
	
	parameter BPS =  196*40,   //25M/128000~=196clk
		
	//3.select logic counter from 50 counters  141
	select_incombo = 8'b01001000,
	incombo_PC2 = 8'b0000_0011,
	incombo_PC3 = 8'b0000_0001,
	incombo_PC4 = 8'b0000_1100,
	incombo_PC5 = 8'b0000_0010;
	
	
	
	
	
	
	integer i;
	initial begin
	////////////////////3.select logic counter from 50 counters///////////////////////////////////////////	
		# (30*BPS) rx = 1'b1;
		# BPS rx = 1'b0;  //  start bit
		for(i=0; i<8; i=i+1)
		begin
		# BPS rx = select_incombo[i]; //8bit data bit
		end
		# BPS rx = 1'b1;	// 2bit stop bit 
		# (BPS*2) rx = 1'b1; 	// bus idle
		//PC2
		# (15*BPS) rx = 1'b1;
		# BPS rx = 1'b0;  //  start bit
		for(i=0; i<8; i=i+1)
		begin
		# BPS rx =  incombo_PC2[i]; //8bit data bit
		end
		# BPS rx = 1'b1;	// 2bit stop bit 
		# (BPS*2) rx = 1'b1; 	// bus idle
		//PC3
		# (15*BPS) rx = 1'b1;
		# BPS rx = 1'b0;  //  start bit
		for(i=0; i<8; i=i+1)
		begin
		# BPS rx =  incombo_PC3[i]; //8bit data bit
		end
		# BPS rx = 1'b1;	// 2bit stop bit 
		# (BPS*2) rx = 1'b1; 	// bus idle
		//PC4
		# (15*BPS) rx = 1'b1;
		# BPS rx = 1'b0;  //  start bit
		for(i=0; i<8; i=i+1)
		begin
		# BPS rx =  incombo_PC4[i]; //8bit data bit
		end
		# BPS rx = 1'b1;	// 2bit stop bit 
		# (BPS*2) rx = 1'b1; 	// bus idle
		//PC5
		# (15*BPS) rx = 1'b1;
		# BPS rx = 1'b0;  //  start bit
		for(i=0; i<8; i=i+1)
		begin
		# BPS rx =  incombo_PC5[i]; //8bit data bit
		end
		# BPS rx = 1'b1;	// 2bit stop bit 
		# (BPS*2) rx = 1'b1; 	// bus idle
      end 
		
	parameter CLOCK_DIVIDE = 49; 

   parameter RX_IDLE = 'd0;
	parameter RX_CHECK_START = 'd1;
	parameter RX_READ_BITS = 'd2;
	parameter RX_CHECK_STOP = 'd3;
	parameter RX_DELAY_RESTART = 'd4;
	parameter RX_ERROR = 'd5;
	parameter RX_RECEIVED = 'd6;
	
	reg [2:0] recv_state;
	reg [10:0] rx_clk_divider;
	reg [5:0] rx_countdown;
	reg [4:0] rx_bits_remaining;
	reg [7:0] rx_data;
	
	initial begin
		recv_state = RX_IDLE;
	end
	
   // The clk_divider counter counts down from
	// the CLOCK_DIVIDE constant. Whenever it
	// reaches 0, 1/16 of the bit period has elapsed.
   // Countdown timers for the receiving and transmitting
	// state machines are decremented.
always #40 begin 
	
	rx_clk_divider = rx_clk_divider - 1'b1;
	if (!rx_clk_divider) begin
		rx_clk_divider = CLOCK_DIVIDE;
		rx_countdown = rx_countdown - 1'b1;
	end
	
	// Receive state machine
	case (recv_state)
		RX_IDLE: begin
			// A low pulse on the receive line indicates thealways
			// start of data.
			if (!tx) begin
				// Wait half the period - should resume in the
				// middle of this first pulse.
				rx_clk_divider = CLOCK_DIVIDE;
				rx_countdown = 2;  //!wait 2 clock
				recv_state = RX_CHECK_START;
			end
		end
		RX_CHECK_START: begin
				// Check the pulse is still there
				if (!tx) begin
					// Pulse still there - good
					// Wait the bit period to resume half-way                                                                                                                                                    

					// through the first bit.
					rx_countdown = 4;
					rx_bits_remaining = 8;
					recv_state = RX_READ_BITS;
				end else begin
					// Pulse lasted less than half the period -
					// not a valid transmission.
					recv_state = RX_ERROR;
				end
		end
		RX_READ_BITS: begin
			if (!rx_countdown) begin
				// Should be half-way through a bit pulse here.
				// Read this bit in, wait for the next if we
				// have more to get.
				rx_data = {tx, rx_data[7:1]};
				rx_countdown = 4;
				rx_bits_remaining = rx_bits_remaining - 1;
				recv_state = rx_bits_remaining ? RX_READ_BITS : RX_CHECK_STOP;
			end
		end
		RX_CHECK_STOP: begin
			if (!rx_countdown) begin
				// Should resume half-way through the stop bit
				// This should be high - if not, reject the
				// transmission and signal an error.
				recv_state = tx ? RX_RECEIVED : RX_ERROR;
			end 
		end
		RX_DELAY_RESTART: begin
			// Waits a set number of cycles before accepting
			// another transmission.
			recv_state = rx_countdown ? RX_DELAY_RESTART : RX_IDLE;
		end
		RX_ERROR: begin
			// There was an error receiving.
			// Raises the recv_error flag for one clock
			// cycle while in this state and then waits
			// 2 bit periods before accepting another
			// transmission.
			rx_countdown = 8;
			recv_state = RX_DELAY_RESTART;
		end
		RX_RECEIVED: begin
			// Successfully received a byte.
			// Raises the received flag for one clock
			// cycle while in this state.
			recv_state = RX_IDLE; 
			echo = rx_data;
		end
	endcase
  end	
endmodule


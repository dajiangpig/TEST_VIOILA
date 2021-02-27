`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:21:23 11/04/2018 
// Design Name: 
// Module Name:    uart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart(
    input clk,
    input rst, // Synchronous reset.
    input rx, // Incoming serial line
    output tx, // Outgoing serial line
    input transmit, // Signal to transmit
    input [7:0] tx_byte, // Byte to transmit
    output received, // Indicated that a byte has been received.
    output [7:0] rx_byte, // Byte received
    output is_receiving, // Low when receive line is idle.
    output is_transmitting, // Low when transmit line is idle.
    output recv_error // Indicates error in receiving packet.
	 //debugg
	// output  wire [10:0] rx_clk_divider1,
	 //output wire [10:0] tx_clk_divider1,
	 //output wire [2:0] recv_state1,
//	 //output wire [5:0] rx_countdown1,
//	 output wire [3:0] rx_bits_remaining1,
//	 output wire [7:0] rx_data1,
//	 output wire tx_out1,
//	 output wire [7:0] tx_state1,
//	 output wire [5:0] tx_countdown1,
//	 output wire [3:0] tx_bits_remaining1,
//	 output wire [7:0] tx_data1
// 
    );
  

//BELOW SEGMENT ADDED-JS
//assign rx_countdown_out = rx_countdown;
//assign tx_countdown_out = tx_countdown;

// BELOW FOR OPERATION AT 9600 BAUD 
//parameter CLOCK_DIVIDE = 1302; // clock rate (50Mhz) / (baud rate (9600) * 4)

// BELOW FOR OPERATION AT 128000 BAUD 
//parameter CLOCK_DIVIDE = 98; // clock rate (50Mhz) / (baud rate * 4)
parameter CLOCK_DIVIDE = 49;  // clock rate (25 MHz) / (baud rate * 4)
//parameter CLOCK_DIVIDE = 39; // clock rate (20 MHz) / (baud rate * 4)
//parameter CLOCK_DIVIDE = 'd10;  // clock rate (5 MHz) / (baud rate * 4)  !9.76  ???????????4????????????¦Ë????4?¦²????????????????4????128000*4?????????????????5M/(128000*4s)??
//parameter CLOCK_DIVIDE = 6;  // clock rate (3 MHz) / (baud rate * 4)

// BELOW FOR OPERATION AT 115200 BAUD (had trouble with this one)
//parameter CLOCK_DIVIDE = 109; // clock rate (50Mhz) / (baud rate * 4)

// ADDED-JS: BELOW FOR 57600 BAUD (FOR QUICKER SIMULATION ONLY-#17361 on tcoinc.v)
//parameter CLOCK_DIVIDE = 217;

// States for the receiving state machine.
// These are just constants, not parameters to override.
parameter RX_IDLE = 'd0;
parameter RX_CHECK_START = 'd1;
parameter RX_READ_BITS = 'd2;
parameter RX_CHECK_STOP = 'd3;
parameter RX_DELAY_RESTART = 'd4;
parameter RX_ERROR = 'd5;
parameter RX_RECEIVED = 'd6;

// States for the transmitting state machine.
// Constants - do not override.
parameter TX_IDLE = 'd0;
parameter TX_SENDING = 'd1;
parameter TX_DELAY_RESTART = 'd2;

reg [10:0] rx_clk_divider = CLOCK_DIVIDE;
reg [10:0] tx_clk_divider = CLOCK_DIVIDE;

assign rx_clk_divider1=rx_clk_divider;
assign tx_clk_divider1=tx_clk_divider;

reg [2:0] recv_state = RX_IDLE;
reg [5:0] rx_countdown;
reg [4:0] rx_bits_remaining;
reg [7:0] rx_data;

assign recv_state1=recv_state;
assign rx_countdown1=rx_countdown;
assign rx_bits_remaining1=rx_bits_remaining;
assign rx_data1=rx_data;


reg tx_out = 1'b1;
reg [1:0] tx_state = TX_IDLE;
reg [5:0] tx_countdown;
reg [4:0] tx_bits_remaining;
reg [7:0] tx_data;
assign tx_out1=tx_out;
assign tx_state1=tx_state;
assign tx_countdown1=tx_countdown;
assign tx_bits_remaining1=tx_bits_remaining;
assign tx_data1=tx_data;



assign received = recv_state == RX_RECEIVED;
assign recv_error = recv_state == RX_ERROR;
assign is_receiving = recv_state != RX_IDLE;
assign rx_byte = rx_data;

assign tx = tx_out;
assign is_transmitting = tx_state != TX_IDLE;

always @(posedge clk) begin
	if (rst) begin
		recv_state = RX_IDLE;
		tx_state = TX_IDLE;
	end
	
	// The clk_divider counter counts down from
	// the CLOCK_DIVIDE constant. Whenever it
	// reaches 0, 1/16 of the bit period has elapsed.
   // Countdown timers for the receiving and transmitting
	// state machines are decremented.
	rx_clk_divider = rx_clk_divider - 1'b1;
	if (!rx_clk_divider) begin
		rx_clk_divider = CLOCK_DIVIDE;
		rx_countdown = rx_countdown - 1'b1;
	end
	tx_clk_divider = tx_clk_divider - 1'b1;
	if (!tx_clk_divider) begin
		tx_clk_divider = CLOCK_DIVIDE;
		tx_countdown = tx_countdown - 1'b1;
	end
	
	// Receive state machine
	case (recv_state)
		RX_IDLE: begin
			// A low pulse on the receive line indicates the
			// start of data.
			if (!rx) begin
				// Wait half the period - should resume in the
				// middle of this first pulse.
				rx_clk_divider = CLOCK_DIVIDE;
				rx_countdown = 2;  //!wait 2 clock
				recv_state = RX_CHECK_START;
			end
		end
		RX_CHECK_START: begin
			if (!rx_countdown) begin
				// Check the pulse is still there
				if (!rx) begin
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
		end
		RX_READ_BITS: begin
			if (!rx_countdown) begin
				// Should be half-way through a bit pulse here.
				// Read this bit in, wait for the next if we
				// have more to get.
				rx_data = {rx, rx_data[7:1]};
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
				recv_state = rx ? RX_RECEIVED : RX_ERROR;
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
		end
	endcase
	
	// Transmit state machine
	case (tx_state)
		TX_IDLE: begin
			if (transmit) begin
				// If the transmit flag is raised in the idle
				// state, start transmitting the current content
				// of the tx_byte input.
				tx_data = tx_byte;
				// Send the initial, low pulse of 1 bit period
				// to signal the start, followed by the data
				tx_clk_divider = CLOCK_DIVIDE;
				tx_countdown = 4;
				tx_out = 0;
				tx_bits_remaining = 8;
				tx_state = TX_SENDING;
			end
		end
		TX_SENDING: begin
			if (!tx_countdown) begin
				if (tx_bits_remaining) begin
					tx_bits_remaining = tx_bits_remaining - 1'b1;
					tx_out = tx_data[0];
					tx_data = {1'b0, tx_data[7:1]};
					tx_countdown = 4;
					tx_state = TX_SENDING;
				end else begin
					// Set delay to send out 2 stop bits.
					tx_out = 1;
					tx_countdown = 8;
					tx_state = TX_DELAY_RESTART;
				end
			end
		end
		TX_DELAY_RESTART: begin
			// Wait until tx_countdown reaches the end before
			// we send another transmission. This covers the
			// "stop bit" delay.
			tx_state = tx_countdown ? TX_DELAY_RESTART : TX_IDLE;
		end
	endcase
end

endmodule

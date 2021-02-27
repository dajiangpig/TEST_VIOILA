`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:11:04 08/07/2020 
// Design Name: 
// Module Name:    vioila_test 
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
module vioila_test(

    input CLK_50M,
    input rx,
    output tx	 
// 下面是注释	，debug用的
//    output rst,
//    output rx_byte,
//    output tx_byte_bus,
//    output transmit_bus,
//    output CLK_BUS,
//    output CLK_UART	 
    );

reg 		 rst=1'b1;

always@(posedge CLK_UART)
  begin
	if	(rst)
	 begin
		rst <= 0;	
	 end
  end	 

always@(posedge CLK_BUS)
	begin
		if(!rst && received)
		begin
       tx_byte_bus <= rx_byte;
		 transmit_bus <= 1;
    	end	
		if (is_transmitting)
		 transmit_bus <= 0;
	end  

wire [7:0] rx_byte;
reg [7:0] tx_byte_bus;
reg transmit_bus;
wire [7:0] tx_byte_vio;
//assign tx_byte_bus = tx_byte_vio;

pll pll_inst(
.CLK_IN1(CLK_50M),
.CLK_OUT1(CLK_BUS),
.CLK_OUT2(CLK_UART)
); 

wire [35:0] ila_cntr, vio_cntr;

ICON ICON_inst(
.CONTROL0(ila_cntr),
.CONTROL1(vio_cntr)
);

ILA ILA_inst(
.CONTROL(ila_cntr),
.TRIG0(rx_byte),
.TRIG1(tx_byte_bus),
.CLK(CLK_UART)
);
 
VIO VIO_inst(
.CONTROL(vio_cntr),
.ASYNC_IN(rx_byte),
.ASYNC_OUT(tx_byte_vio)
);

 
uart uart_inst
(
    .clk(CLK_UART),
    .rst(rst), // Synchronous reset.
    .rx(rx), // Incoming serial line
    .tx(tx), // Outgoing serial line
    .transmit(transmit_bus), // Signal to transmit
    .tx_byte(tx_byte_vio), // Byte to transmit
    .received(received), // Indicated that a byte has been received.
    .rx_byte(rx_byte), // Byte received
    .is_receiving(is_receiving), // Low when receive line is idle.
    .is_transmitting(is_transmitting), // Low when transmit line is idle.
    .recv_error(recv_error) // Indicates error in receiving packet.
);

endmodule

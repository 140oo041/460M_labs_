`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.10.2026 14:49:46
// Design Name: 
// Module Name: one_bit_rec_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module one_bit_rec_tb(
    
    );
    
    reg clk;
    reg rst;
    reg data_in;
    reg send_async;
    wire data_out;
    wire RX_EVENT;

    
    wire ack;
    wire req;
    wire data_master;

    
    
    
    one_bit_receiver rx_dut(clk,rst,req,data_master,
 data_out,ack, RX_EVENT);
 
 tx_1bit tx_dut(
    clk,
    rst,
    data_in,
    send_async,
    ack,
    req,
    data_master
);

always #5 clk = ~clk;

initial begin
   clk = 0;
   rst = 1;
   data_in = 0;
   send_async = 0;
   #10;
   rst = 0;
   send_async = 1;
   #20;
   send_async = 0;
   #100;
    data_in = 1;
   #5;
   send_async = 1;
   #20;
   send_async =0;
end
endmodule



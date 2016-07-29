`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:00:49 02/08/2016 
// Design Name: 
// Module Name:    async_rst_syncrelase 
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
module async_rst_syncrelase(
input		clk,
input		rstn,
output	rstn2
    );
reg		rstn1;
reg		rstn2;
always @(posedge clk or negedge rstn)
begin
if(!rstn) rstn1<=1'b0;
else
rstn1<=1'b1;
end
always @(posedge clk or negedge rstn)
begin
if(!rstn) rstn2<=1'b0;
else
rstn2<=rstn1;
end
endmodule

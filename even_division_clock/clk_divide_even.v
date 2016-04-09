`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: zdfmessi
// 
// Create Date:    15:00:06 04/09/2016 
// Design Name: 
// Module Name:    clk_divide_even 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: even division of clock
//
// Dependencies: 
//
// Revision: v1.0
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_divide_even(
	input clk,
	input rstn,
	output clk_even
    );
	localparam N=8;
	reg [N/2:0] cnt;
	reg clk_even_r;
	
	always @(posedge clk)
		if(!rstn) begin
			cnt <= 4'b0;
			clk_even_r <= 1'b0;
		end
		else if (cnt == (N/2-1)) begin
			cnt <= 4'b0;
			clk_even_r <= ~clk_even_r;
		end
				else begin
			cnt <= cnt+1'b1;
			clk_even_r <= clk_even_r;
				end
	assign clk_even = clk_even_r;
	

endmodule

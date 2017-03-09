`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: szu
// Engineer:@zdfmessi 
// 
// Create Date: 2016/12/05 20:21:03
// Design Name: 
// Module Name: divider_48cycle
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: v1.1 create by zdfmessi 2016/12/08 1:07 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define combine
//`define dispersion

module divider_48cycle
#(
 parameter DIVISION_WIDTH   = 32,
 parameter QUOTIENT_WIDTH   = 32,
 parameter FRACTIONAL_WIDTH = 16
)
(
 input                                     clk,
 input                                     rstn,
 input                                     start,
 input       signed [DIVISION_WIDTH-1  :0] dividend,
 input       signed [DIVISION_WIDTH-1  :0] divisor,
 
 `ifdef combine
 output reg     signed  [QUOTIENT_WIDTH+FRACTIONAL_WIDTH-1:0] division_out_o,
 `endif
 `ifdef dispersion
 output  reg    signed [QUOTIENT_WIDTH-1  :0] quotient_r,
 output  reg           [FRACTIONAL_WIDTH-1:0] fractional_r,
 `endif
 output reg                                finish
    );
    //log2b function
    function integer clogb2(input integer data_width);
		begin
			clogb2 = 0;
			data_width = data_width - 1;
			if(data_width) begin
			for (clogb2=1;data_width>1;clogb2=clogb2+1)
				data_width = data_width>>1;
			end
		end
	endfunction
	
   localparam COUNT_WIDTH = clogb2(DIVISION_WIDTH<<1);

   //fsm state
   localparam IDLE = 2'd1;
   localparam CALC = 2'd2;
   
   reg  				[DIVISION_WIDTH-2                 :0] dividend_f;
   reg  				[DIVISION_WIDTH-2                 :0] divisor_f;
   reg  				[DIVISION_WIDTH-2                 :0] dividend_r;
   reg  				[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:0] division_out_r;
   reg  				[COUNT_WIDTH-1                    :0] calc_count;
   reg  				[1                                :0] state;
	 reg                                        				calc_valid;
   wire                                       				sign_flag;
   wire 				[1                                :0] msb_bits;
	 wire	signed  [QUOTIENT_WIDTH+FRACTIONAL_WIDTH-1:0] division_out;
	 wire	signed 	[QUOTIENT_WIDTH-1  								:0] quotient;
	 wire         [FRACTIONAL_WIDTH-1								:0] fractional;
	 
   assign msb_bits = {dividend[DIVISION_WIDTH-1],divisor[DIVISION_WIDTH-1]};


   always @(posedge clk)
     begin
       if(!rstn) begin
					state <= IDLE;
					dividend_f <= 0;
					divisor_f <= 0;	
					dividend_r <= 0;
					division_out_r <= 0;
					calc_valid <= 1'b0;
       end
       else begin
         case(state)
					IDLE:
					begin
						if(start) begin
							case(msb_bits)
						2'b00: begin
							dividend_f <= dividend[DIVISION_WIDTH-2:0];
							divisor_f <= divisor[DIVISION_WIDTH-2:0];
						end
						2'b01: begin
							dividend_f <= dividend[DIVISION_WIDTH-2:0];
							divisor_f <= (~(divisor[DIVISION_WIDTH-2:0])) + 1'b1;
						end
						2'b10: begin
							dividend_f <= (~(dividend[DIVISION_WIDTH-2:0])) + 1'b1;
							divisor_f <= divisor[DIVISION_WIDTH-2:0];
						end
						2'b11: begin
							dividend_f <= (~(dividend[DIVISION_WIDTH-2:0])) + 1'b1;
							divisor_f <= (~(divisor[DIVISION_WIDTH-2:0])) + 1'b1;
									end
						default: begin
							dividend_f <= dividend_f;
							divisor_f <= divisor_f; 
						end
								endcase
								dividend_r <= dividend[DIVISION_WIDTH-2];
								state <= CALC;
								calc_valid <= 1'b1;
									end
					end
					CALC:
					begin
						if(!finish) begin
								division_out_r <= division_out_r<<1;
								dividend_f <= dividend_f<<1;		 
							if(dividend_r >= divisor_f) begin
								division_out_r[0] <= 1'b1;
								dividend_r <= (dividend_r - divisor_f)<<1;
							end
							else begin
								division_out_r[0] <= 1'b0;
								dividend_r <= dividend_r<<1;
							end
								dividend_r[0] <= dividend_f[DIVISION_WIDTH-2];
						end
						else begin
								calc_valid <= 1'b0;
								state <= IDLE;
						end
					end
					default:
					begin
						state <= IDLE;
					end
					endcase
							end       
						end	     
   
   //calc count
   always @(posedge clk)
    begin
      if(!rstn)
        begin
					calc_count <= 0;
					finish <= 1'b0;
				end
			else begin 
				if(calc_valid)
          begin
						if(calc_count == DIVISION_WIDTH + FRACTIONAL_WIDTH)
							begin
								calc_count <= 0;
								finish <= 1'b1;
							end
						else begin
								calc_count <= calc_count + 1'b1;
								finish <= 1'b0;
							end       
					end
				else begin
						calc_count <= 0;
						finish <= 1'b0;
					end   
        end
    end
	
  assign sign_flag = ((dividend[(DIVISION_WIDTH-1)])^(divisor[(DIVISION_WIDTH-1)]));
  
	`ifdef dispersion
	assign quotient = ((sign_flag==1'b1)?({sign_flag,(~(division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]) + 1'b1)}):{sign_flag,division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]});
  assign fractional =(division_out_r[FRACTIONAL_WIDTH-1:0]);
	always @(posedge clk)
		begin
			//if(finish) begin
			quotient_r <= quotient;
			fractional_r <= fractional;
			//end
			//else begin
			//quotient_r <= 0;
			//fractional_r <= 0;
			//end			
		end
	`endif
	
	`ifdef combine
	assign division_out = (sign_flag==1'b1)?{sign_flag,(~(division_out_r) + 1'b1)}:{sign_flag,division_out_r};
	always @(posedge clk)
		begin
			//if(finish)
			division_out_o <= division_out;
			//else 
			//division_out_o <= 0;
		end
	`endif
endmodule

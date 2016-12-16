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
//`define combine
`define dispersion

module divider_48cycle_v3
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
 output wire     signed  [QUOTIENT_WIDTH+FRACTIONAL_WIDTH-1:0] division_out,
 `endif
 `ifdef dispersion
 output      signed [QUOTIENT_WIDTH-1  :0] quotient,
 output             [FRACTIONAL_WIDTH-1:0] fractional,
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
   
   reg  [DIVISION_WIDTH-1                 :0] dividend_f;
   reg  [DIVISION_WIDTH-1                 :0] divisor_f;
   reg  [DIVISION_WIDTH-2                 :0] dividend_r;
   reg  [DIVISION_WIDTH-2                 :0] dividend_r_f;
   reg  [DIVISION_WIDTH-2                 :0] divisor_r;
   reg  [DIVISION_WIDTH+FRACTIONAL_WIDTH-2:0] division_out_r;
   reg  [COUNT_WIDTH-1                    :0] calc_count;
   reg  [1                                :0] state;
   reg                                        calc_en;
   wire                                       sign_flag;
   wire [1                                :0] msb_bits;
	 reg                                        start1;
	 reg                                        calc_valid;
	 
	 always @(posedge clk)
	  begin
		  start1 <= start;
		end

   assign msb_bits = {dividend[DIVISION_WIDTH-1],divisor[DIVISION_WIDTH-1]};

   always @(posedge clk)
     begin
       case(msb_bits)
	  2'b00: begin
	    dividend_f <= dividend;
	    divisor_f <= divisor;
	   end
	  2'b01: begin
	    dividend_f <= dividend;
	    divisor_f <= (~divisor) + 1'b1;
	   end
	  2'b10: begin
	    dividend_f <= (~dividend) + 1'b1;
	    divisor_f <= divisor;
	   end
	  2'b11: begin
	    dividend_f <= (~dividend) + 1'b1;
	    divisor_f <= (~divisor) + 1'b1;
           end
	  default: begin
	    dividend_f <= dividend_f;
	    divisor_f <= divisor_f; 
	   end
        endcase
     end


   always @(posedge clk)
     begin
       if(!rstn) begin
         state <= IDLE;
	 dividend_r <= 0;
	 divisor_r <= 0;
	 division_out_r <= 0;
	 calc_valid <= 1'b0;
       end
       else begin
         case(state)
	 IDLE:
	 begin
		 if(start1) begin	
		    dividend_r <= dividend_f[DIVISION_WIDTH-2];
		    dividend_r_f <= dividend_f[DIVISION_WIDTH-2:0];
		    divisor_r <= divisor_f[DIVISION_WIDTH-2:0];
		    state <= CALC;
				calc_valid <= 1'b1;
	         end
	 end
	 CALC:
	 begin
	   if(!finish) begin
	     if(dividend_r >= divisor_r) begin
	       division_out_r <= division_out_r<<1;
	       division_out_r[0] <= 1'b1;
	       dividend_r_f <= dividend_r_f<<1;
	       dividend_r <= (dividend_r - divisor_r)<<1;
	       dividend_r[0] <= dividend_r_f[DIVISION_WIDTH-2]; 
	     end
	     else begin
	       division_out_r <= division_out_r<<1;
	       division_out_r[0] <= 1'b0;
	       dividend_r_f <= dividend_r_f<<1;
	       dividend_r <= dividend_r<<1;
	       dividend_r[0] <= dividend_r_f[DIVISION_WIDTH-2]; 
	     end
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
	       if(calc_count == DIVISION_WIDTH + FRACTIONAL_WIDTH-1)
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
  /* assign quotient = (finish==1'b1)?((sign_flag==1'b1)?({sign_flag,(~(division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]) + 1'b1)}):{sign_flag,division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]}):{(QUOTIENT_WIDTH){1'b0}};
  assign fractional = (finish==1'b1)? (division_out_r[FRACTIONAL_WIDTH-1:0]):{(FRACTIONAL_WIDTH){1'b0}}; */
	`ifdef dispersion
	assign quotient = ((sign_flag==1'b1)?({sign_flag,(~(division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]) + 1'b1)}):{sign_flag,division_out_r[DIVISION_WIDTH+FRACTIONAL_WIDTH-2:FRACTIONAL_WIDTH]});
  assign fractional =(division_out_r[FRACTIONAL_WIDTH-1:0]);
	`endif
	
	`ifdef combine
	assign division_out = (sign_flag==1'b1)?{sign_flag,(~(division_out_r) + 1'b1)}:{sign_flag,division_out_r};
	`endif
endmodule

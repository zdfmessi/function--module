`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: szu
// Engineer: @zdfmessi
// 
// Create Date:    21:23:26 12/23/2016 
// Design Name: 
// Module Name:    kalman_filter_v3 
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
module kalman_filter_v3(
	input		wire														clk,
	input		wire														rstn,
	input		wire														valid,
	input		wire	signed	[DATA_WIDTH-1:0]	I_data_x,
	output	wire	signed	[DATA_WIDTH-1:0]	O_filter_data_x,
	output	reg															finish
  );
	
	parameter	DATA_WIDTH				=	32;
	parameter	MATRIX_WIDTH			= 32;
	parameter	FIX_POINT_WIDTH		=	16;
	
	parameter Q_value						=	32'h0000_1999;//0.1    028f---0.01
	parameter	FIRST_STAGE_R			= 32'h03e8_0000;
	parameter	SECOND_STAGE_R		=	32'h07d0_0000;
	parameter	THIRD_STAGE_R			=	32'h0bb8_0000;
	parameter	FOURTH_STAGE_R		=	32'h0fa0_0000;
	parameter	FIFTH_STAGE_R			=	32'h1388_0000;
	
	//----main FSM state----//
	localparam	IDLE						=	3'd1;
	localparam	ESTIMATE				=	3'd2;
	localparam	KCOE						=	3'd3;
	localparam	UPDATE					=	3'd4;
	
	//----update FSM state----//
	localparam	UPDATE_IDLE			=	3'd1;
	localparam	UPDATE_STEP1		=	3'd2;
	localparam	UPDATE_STEP2		=	3'd3;
	localparam	UPDATE_STEP3		=	3'd4;
	localparam	UPDATE_STEP4		= 3'd5;
	localparam	UPDATE_END			=	3'd6;
	
	
	
	//--------------------------------------------------//
	//								internal registers								//
	//--------------------------------------------------//
	
	//----x data resisters----//
	reg signed	[MATRIX_WIDTH-1:0]	x_est[0:1];
	reg	signed	[MATRIX_WIDTH-1:0]	xp_est[0:3];
	reg	signed	[MATRIX_WIDTH-1:0]	xk[0:1];
	reg signed	[MATRIX_WIDTH-1:0]	x_update[0:1];
	reg	signed	[MATRIX_WIDTH-1:0]	p_update[0:3];
	
	//----state registers----//
	reg	[2:0] main_current_state;
	reg [2:0] main_next_state;
	
	reg [2:0]	update_current_state;
	reg [2:0] update_next_state;
	
	
	
	reg	[DATA_WIDTH-1:0]	R_value;
	
	wire																						update_start;
	reg																							update_finish;
	reg																							divider_start;
	wire																						k0_divider_finish;
	wire																						k1_divider_finish;
	
	wire	signed [MATRIX_WIDTH-1:0]	k0_dividend_in,k1_dividend_in;
	wire	signed [MATRIX_WIDTH-1:0]	k0_divisor_in,k1_divisor_in;
	wire	signed [MATRIX_WIDTH+FIX_POINT_WIDTH-1:0]	k0_division_result,k1_division_result;
	
	
	//----function calculate the R value----//
	function	integer r_value(input integer data);
		begin
			r_value = 0;
				if(data>32'h0028_0000)
					r_value = FIRST_STAGE_R;
				else if((data>32'h001e_0000))
					r_value = SECOND_STAGE_R;
				else if((data>32'h0014_0000))
					r_value = SECOND_STAGE_R;
				else if((data>32'h000a_0000))
					r_value = THIRD_STAGE_R;
				else if((data>32'h0005_0000))
					r_value = FOURTH_STAGE_R;
				else if((data>32'h0000_0000))
					r_value = FIFTH_STAGE_R;
				else r_value = r_value;
			end
			
	endfunction
	
	//----calculate the absolute value----//
	function	[31:0] abs_value(input [31:0] data);
		begin
			abs_value = 0;
			if(data[31])
				abs_value = -data;//calculate the complement of a signed value
			else	abs_value = data;	
		end
	endfunction
	
	reg [DATA_WIDTH-1:0] abs_r_value;
	
	always @(posedge clk)
		begin
			if(!rstn)
				abs_r_value <= 'h0;
			else abs_r_value <= abs_value(x_update[0]-I_data_x);	
		end
	
	reg [DATA_WIDTH-1:0] R;
	always @(posedge clk)
		begin
			if(!rstn)
				R <= 'h0;
			else R <= r_value(abs_r_value);	
		end
		
		
	
	//-----------------------main FSM of kalman filter------------------------------//
	
	//----the first process----//
	always @(posedge clk)
		begin
			if(!rstn) 
				main_current_state <= IDLE;
			else 
				main_current_state <= main_next_state;
		end
		
	//----the second process----//
	always @(*)
		begin
			main_next_state = IDLE;
			case(main_current_state)
				IDLE: 
					begin
						if(valid)
							main_next_state = ESTIMATE;
						else
							main_next_state = IDLE;
					end
				ESTIMATE: 
					begin
						main_next_state = KCOE;
					end
				KCOE:
					begin
						if(k0_divider_finish)
							main_next_state = UPDATE;
						else
							main_next_state = KCOE;
					end
				UPDATE:
					begin
						if(update_finish)
							main_next_state = IDLE;
						else
							main_next_state = UPDATE;
					end
			endcase		
		end
		
	//----the third process----//
	always @(posedge clk)
		begin
			if(!rstn)
				begin
					divider_start <= 1'b0;
					x_update[0] <= 'h0;
					x_update[1] <= 'h0;
					p_update[0] <= 'h0005_0000;
					p_update[1] <= 'h0;
					p_update[2] <= 'h0;
					p_update[3] <= 'h0005_0000;
					R_value <= 'h03e8_0000;
					xp_est[0] <= 'h0;
					xp_est[1] <= 'h0;
					xk[0] <= 'h0;
					xk[1] <= 'h0;
					R_value <= 'h0000_0000;	
				end
			else begin
				case(main_next_state)
					IDLE:
						begin
							divider_start <= 1'b0;
						end
					ESTIMATE:
						begin
							divider_start <= 1'b1;
							R_value <= R;
							x_est[0] <= x_update[0] + x_update[1];
							x_est[1] <= x_update[1];
							xp_est[0] <= p_update[0] + p_update[1] + p_update[2] + p_update[3] + Q_value;
							xp_est[1] <= p_update[1] + p_update[3];
							xp_est[2] <= p_update[2] + p_update[3];
							xp_est[3] <= p_update[3] + Q_value;
						end
					KCOE:
						begin
							divider_start <= 1'b0;
							xk[0] <= k0_division_result[MATRIX_WIDTH-1:0];
							xk[1] <= k1_division_result[MATRIX_WIDTH-1:0];
						end
					UPDATE:
						begin
							x_update[0] <= x_update_r4[0];
							x_update[1] <= x_update_r4[1];
							p_update[0] <= p_update_r3[0];
							p_update[1] <= p_update_r3[1];
							p_update[2] <= p_update_r3[2];
							p_update[3] <= p_update_r3[3];							
						end
				endcase		
			end			
		end
		

		assign update_start = k0_divider_finish;
		assign k0_dividend_in = xp_est[0];
		assign k0_divisor_in = xp_est[0] + R_value;
		assign k1_dividend_in = xp_est[2];
		assign k1_divisor_in = xp_est[0] + R_value;
		
		
		
		divider_48cycle U_k0_divider(
			.clk(clk), 
			.rstn(rstn), 
			.start(divider_start), 
			.dividend(k0_dividend_in), 
			.divisor(k0_divisor_in), 
			.division_out_o(k0_division_result), 
			.finish(k0_divider_finish)
		); 
		
		divider_48cycle U_k1_divider(
			.clk(clk), 
			.rstn(rstn), 
			.start(divider_start), 
			.dividend(k1_dividend_in), 
			.divisor(k1_divisor_in), 
			.division_out_o(k1_division_result), 
			.finish(k1_divider_finish)
		); 
		
		
		
		
	//----------------------------update FSM of kalman filter---------------------------//
	always @(posedge clk)
		begin
			if(!rstn)
				update_current_state <= UPDATE_IDLE;
			else
				update_current_state <= update_next_state;
		end
		
	always @(*)
		begin
			update_next_state = UPDATE_IDLE;
			case(update_current_state)
				UPDATE_IDLE:
					begin
						if(update_start)
							update_next_state = UPDATE_STEP1;
						else
							update_next_state = UPDATE_IDLE;
					end
				UPDATE_STEP1:
					begin
							update_next_state = UPDATE_STEP2;
					end
				UPDATE_STEP2:
					begin
							update_next_state = UPDATE_STEP3;
					end
				UPDATE_STEP3:
					begin
							update_next_state = UPDATE_STEP4;
					end	
				UPDATE_STEP4:
					begin
						update_next_state = UPDATE_END;
					end
				UPDATE_END:
					begin
						update_next_state = UPDATE_IDLE;
					end
				endcase				
		end
		
		reg signed [MATRIX_WIDTH-1									:0] x_update_r1[0:1];
		reg signed [MATRIX_WIDTH*2-1								:0]	x_update_r2[0:1];
		reg	signed [MATRIX_WIDTH+FIX_POINT_WIDTH-1	:0]	x_update_r3[0:1];
		reg signed [MATRIX_WIDTH-1									:0]	x_update_r4[0:1];
		reg	signed [MATRIX_WIDTH*2-1								:0]	p_update_r1[0:3];
		reg signed [MATRIX_WIDTH+FIX_POINT_WIDTH-1	:0]	p_update_r2[0:3];
		reg signed [MATRIX_WIDTH-1									:0]	p_update_r3[0:3];
		reg	step[0:0];
		
	always @(posedge clk)
		begin
			if(!rstn)
				begin
					finish	<= 1'b0;
					update_finish <= 1'b0;
					step[0] <= 1'b0;
					x_update_r1[0] <=	'h0;
					x_update_r1[1] <= 'h0;
					x_update_r2[0] <=	'h0;
					x_update_r2[1] <= 'h0;
					x_update_r3[0] <=	'h0;
					x_update_r3[1] <= 'h0;
					x_update_r4[0] <=	'h0;
					x_update_r4[1] <= 'h0;
				end
			else begin
					case(update_next_state)
						UPDATE_IDLE:
							begin
								step[0] <= 1'b1;
								finish	<= 1'b0;
								update_finish <= 1'b0;
							end
						UPDATE_STEP1:
							begin
								x_update_r1[0] <= I_data_x - x_est[0]; 
								x_update_r1[1] <= I_data_x;
							end
						UPDATE_STEP2:
							begin
								x_update_r2[0] <= x_update_r1[0] * xk[0];
								x_update_r2[1] <= x_update_r1[0] * xk[1];
								p_update_r1[0] <= xp_est[0] * xk[0];
								p_update_r1[1] <= xp_est[1] * xk[0];
								p_update_r1[2] <= xp_est[0] * xk[1];
								p_update_r1[3] <= xp_est[1] * xk[1];
							end
						UPDATE_STEP3:
							begin
								x_update_r3[0] <= x_update_r2[0]>>>16;
								x_update_r3[1] <= x_update_r2[1]>>>16;
								p_update_r2[0] <= p_update_r1[0]>>>16;
								p_update_r2[1] <= p_update_r1[1]>>>16;
								p_update_r2[2] <= p_update_r1[2]>>>16;
								p_update_r2[3] <= p_update_r1[3]>>>16;
							end
						UPDATE_STEP4:
							begin
								x_update_r4[0] <= x_est[0] + x_update_r3[0][31:0];
								x_update_r4[1] <= x_est[1] + x_update_r3[1][31:0];
								p_update_r3[0] <= xp_est[0] - p_update_r2[0];
								p_update_r3[1] <= xp_est[1] - p_update_r2[1];
								p_update_r3[2] <= xp_est[2] - p_update_r2[2];
								p_update_r3[3] <= xp_est[3] - p_update_r2[3][31:0];
							end
						UPDATE_END:
							begin
								update_finish <= 1'b1;
								finish	<= 1'b1;
							end
						endcase
				end
		end
	
	assign O_filter_data_x = x_update_r4[0];		
		
endmodule

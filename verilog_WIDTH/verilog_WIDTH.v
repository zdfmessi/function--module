	parameter C_COORD_WIDTH           = 11,
    parameter C_PIX_DATA_WIDTH        = 8,//must be equal or less than 32
    parameter C_DATA_IN_WIDTH         = C_PIX_DATA_WIDTH+C_COORD_WIDTH+1,
	
	input wire [C_DATA_IN_WIDTH-1:0]         wdata_OutRam0_i,
	
	wire [C_PIX_DATA_WIDTH-1:0]                  data0_p;
	wire [C_COORD_WIDTH-1:0]                     y0_p;
	wire                                         lend_p;
	
	assign data0_p = wdata_OutRam0_i[C_PIX_DATA_WIDTH-1-:C_PIX_DATA_WIDTH];//从C_PIX_DATA_WIDTH-1，往下取C_PIX_DATA_WIDTH位宽赋值
    assign y0_p    = wdata_OutRam0_i[C_DATA_IN_WIDTH-2-:C_COORD_WIDTH];//从第二高位，往下取C_COORD_WIDTH位宽赋值
    assign lend_p  = wdata_OutRam0_i[C_DATA_IN_WIDTH-1];//MSB 
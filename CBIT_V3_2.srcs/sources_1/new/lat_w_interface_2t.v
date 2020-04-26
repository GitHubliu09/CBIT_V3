`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Additional Comments:
// 偏移二进制码：补码的数据位取反
// 2020.2.21
//////////////////////////////////////////////////////////////////////////////////

module lat_w_interface_2t(
	input		[15:0]data_r,//adc采集的数据（偏移二进制码）从ram里面取出来
	input		collect_once,//使能信号,1个周期即可
	input		clk_60m,//时钟60MHz 工作周期16.66ns
	input		rst,
	
	output	[13:0]	data_time,// data_time = data_arrive + DELAY_TIME
	output	[15:0]	add_r,//读ram地址
	output	wire	en_read,//读ram使能
	output	reg	CAL_END//计算完成标志
);
parameter		DELAY_TIME = 16'd0;//延时1us时设置为20（对应20M时钟）


reg			cal_en;
reg			cal_en_dly;
reg	[2:0]		collect_once_rcd = 3'b000;
reg	[15:0]		r_addr;
reg	[12:0]		data_conuter;
reg	[15:0]		abs_data;
reg	[17:0]		abs_Ldata_dly1,abs_Ldata_dly2,abs_Ldata_dly3,abs_Ldata_dly4,abs_Ldata_dly5;
reg	[17:0]		abs_Ldata_dly6,abs_Ldata_dly7,abs_Ldata_dly8,abs_Ldata_dly9,abs_Ldata_dly10;
reg	[17:0]		abs_Ldata_dly11,abs_Ldata_dly12,abs_Ldata_dly13,abs_Ldata_dly14,abs_Ldata_dly15;
reg	[17:0]		abs_Ldata_dly16,abs_Ldata_dly17,abs_Ldata_dly18,abs_Ldata_dly19,abs_Ldata_dly20;
reg	[17:0]		abs_Ldata_dly21,abs_Ldata_dly22,abs_Ldata_dly23,abs_Ldata_dly24,abs_Ldata_dly25;
reg	[17:0]		abs_Sdata_dly1,abs_Sdata_dly2,abs_Sdata_dly3;
		
reg	[17:0]		LTA,LTA_t1,LTA_t2,LTA_t3,LTA_t4,LTA_t5,LTA_t6;
reg	[23:0]		LTA_1;
reg	[17:0]		STA,STA_t1,STA_t2,STA_t3,STA_t4;
reg 	[23:0]		STA_1;
		
reg	[23:0]		shang_max;
reg	[23:0]		yushu_max;
reg	[12:0]		count;//记录计算到第几个点
reg	[12:0]		mcount;//长短窗比值最大的点
reg	[23:0]		yushu;//长短窗比值的余数
reg	[23:0]		shang;//长短窗比值的商

//WIRE
wire	[47:0]		m_axis_dout_tdata; 
wire			div_flag;//除法完成标志输出



assign add_r = r_addr;
assign	data_time = mcount + DELAY_TIME - 6'd15 - 2'd3;//减去延迟的周期加短窗的长度，数据出来比使能晚一个周期，减30即可


always @(posedge clk_60m)//检测沿变化
	collect_once_rcd <= {collect_once_rcd[1:0],collect_once};

//产生开始计算的使能信号
always @(posedge clk_60m or posedge rst )
	if(rst == 1'b1)
		cal_en <= 1'b0;
	else if(collect_once_rcd[2:1] == 2'b10)//检测collect_once信号的上升沿 
		cal_en <= 1'b1;
	else if(CAL_END == 1'b1)//计算完成
		cal_en <= 1'b0;

	
always @(posedge clk_60m or posedge rst)
	if(rst == 1'b1)
		data_conuter <= 'd0;
	else if (cal_en == 1'b1)
		data_conuter <= data_conuter + 1'b1;
	else 
		data_conuter <= 'd0;
		
//计算结束信号的产生
always @(posedge clk_60m or posedge rst)
	if(rst == 1'b1)
		CAL_END <= 1'b0;
	else if(data_conuter == 12'd3999 + 6'd31)
	//读ram使能后延迟31个周期输出计算结果：读数据1个周期，码制转换及求绝对值1个周期，数据移入窗内1个周期，
	//对窗求和2个周期，对窗乘法1个周期，除法ip核延迟25个周期，取出商和余数1个周期，判断加输出（到时输出是assign的）
	//即在这个周期就输出了，这个周期不占延时。
		CAL_END <= 1'b1;
	else
		CAL_END <= 1'b0;

assign	en_read = cal_en;//读ram使能

//产生读ram地址
always @(posedge clk_60m or posedge rst)
	if(rst == 1'b1)
		r_addr <= 'd0;
	else if(cal_en == 1'b1)
		r_addr <= r_addr + 1'b1;
	else 
		r_addr <= 'd0;
		
		
	
//使能信号延迟1拍和ram读出的数据对齿
always @(posedge clk_60m)
	cal_en_dly <= cal_en;

/***********构造特征函数***********/
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		abs_data <= 'd0;
	else
		begin
			//offset binary
			if(data_r[15] == 0)//表示负数
				abs_data[15:0] <= {0,(~data_r[14:0] + 1'b1)} ;//取反加一
			else
				abs_data <= data_r[14:0];//正数不变
		end
end

/***********构造长/短窗***********/
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		begin
			abs_Ldata_dly1 <= 17'h00000;
			abs_Ldata_dly2 <= 17'h00000;
			abs_Ldata_dly3 <= 17'h00000;
			abs_Ldata_dly4 <= 17'h00000;
			abs_Ldata_dly5 <= 17'h00000;
			abs_Ldata_dly6 <= 17'h00000;
			abs_Ldata_dly7 <= 17'h00000;
			abs_Ldata_dly8 <= 17'h00000;
			abs_Ldata_dly9 <= 17'h00000;
			abs_Ldata_dly10 <= 17'h00000;
			abs_Ldata_dly11 <= 17'h00000;
			abs_Ldata_dly12 <= 17'h00000;
			abs_Ldata_dly13 <= 17'h00000;
			abs_Ldata_dly14 <= 17'h00000;
			abs_Ldata_dly15 <= 17'h00000;
			abs_Ldata_dly16 <= 17'h00000;
			abs_Ldata_dly17 <= 17'h00000;
			abs_Ldata_dly18 <= 17'h00000;
			abs_Ldata_dly19 <= 17'h00000;
			abs_Ldata_dly20 <= 17'h00000;
			abs_Ldata_dly21 <= 17'h00000;
			abs_Ldata_dly22 <= 17'h00000;
			abs_Ldata_dly23 <= 17'h00000;
			abs_Ldata_dly24 <= 17'h00000;
			abs_Ldata_dly25 <= 17'h00000;
			abs_Sdata_dly1 <= 17'h00000;
			abs_Sdata_dly2 <= 17'h00000;
			abs_Sdata_dly3 <= 17'h00000;
		end
	else
		begin
			abs_Sdata_dly1 <= abs_data;//构造短窗:窗长3
			abs_Sdata_dly2 <= abs_Sdata_dly1;
			abs_Sdata_dly3 <= abs_Sdata_dly2;
			abs_Ldata_dly1 <= abs_Sdata_dly3;//构造长窗:窗长25
			abs_Ldata_dly2 <= abs_Ldata_dly1;
			abs_Ldata_dly3 <= abs_Ldata_dly2;
			abs_Ldata_dly4 <= abs_Ldata_dly3;
			abs_Ldata_dly5 <= abs_Ldata_dly4;
			abs_Ldata_dly6 <= abs_Ldata_dly5;
			abs_Ldata_dly7 <= abs_Ldata_dly6;
			abs_Ldata_dly8 <= abs_Ldata_dly7;
			abs_Ldata_dly9 <= abs_Ldata_dly8;
			abs_Ldata_dly10 <= abs_Ldata_dly9;
			abs_Ldata_dly11 <= abs_Ldata_dly10;
			abs_Ldata_dly12 <= abs_Ldata_dly11;
			abs_Ldata_dly13 <= abs_Ldata_dly12;
			abs_Ldata_dly14 <= abs_Ldata_dly13;
			abs_Ldata_dly15 <= abs_Ldata_dly14;
			abs_Ldata_dly16 <= abs_Ldata_dly15;
			abs_Ldata_dly17 <= abs_Ldata_dly16;
			abs_Ldata_dly18 <= abs_Ldata_dly17;
			abs_Ldata_dly19 <= abs_Ldata_dly18;
			abs_Ldata_dly20 <= abs_Ldata_dly19;
			abs_Ldata_dly21 <= abs_Ldata_dly20;
			abs_Ldata_dly22 <= abs_Ldata_dly21;
			abs_Ldata_dly23 <= abs_Ldata_dly22;
			abs_Ldata_dly24 <= abs_Ldata_dly23;
			abs_Ldata_dly25 <= abs_Ldata_dly24;
		end
end

// 特征函数的求和（没有除窗长）
always @ (posedge clk_60m)
begin
	if(!(cal_en_dly && abs_Ldata_dly25))
		begin
			LTA <= 'd0;
			STA <= 'd0;
		end
	else
		begin
			 LTA_t1 <=abs_Ldata_dly1 +abs_Ldata_dly2 +abs_Ldata_dly3 +abs_Ldata_dly4 + abs_Ldata_dly5 ;
			 LTA_t2 <=  abs_Ldata_dly6 +abs_Ldata_dly7 + abs_Ldata_dly8 + abs_Ldata_dly9 +abs_Ldata_dly10;
			LTA_t3 <=  abs_Ldata_dly11+abs_Ldata_dly12 + abs_Ldata_dly13+abs_Ldata_dly14 + abs_Ldata_dly15;
			LTA_t4 <= abs_Ldata_dly16 + abs_Ldata_dly17+abs_Ldata_dly18+abs_Ldata_dly19+abs_Ldata_dly20;
			LTA_t5 <= abs_Ldata_dly21 + abs_Ldata_dly22+abs_Ldata_dly23+abs_Ldata_dly24 +abs_Ldata_dly25;
			
			LTA <= LTA_t1 + LTA_t2 + LTA_t3 + LTA_t4 + LTA_t5 ;
			STA_t1 <= abs_Sdata_dly1+abs_Sdata_dly2+abs_Sdata_dly3;
			STA <= STA_t1;

		end
end

//特征函数除法转变成乘法，乘法的计算延迟小
always@(posedge clk_60m )
begin
	if(!(cal_en_dly && abs_Ldata_dly25)) begin
		LTA_1 <=  'd0;
		STA_1 <= 'd0;
		
	end
	else begin
		LTA_1 <= LTA*6'd3;
		STA_1 <= STA*6'd25;
	end
end


//除法，计算长短窗的比值
div_gen_2 div_gen_2 (
  .aclk(clk_60m),                                      // input wire aclk
  .s_axis_divisor_tvalid(1'b1 ),    // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata(LTA_1),      // input wire [23 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(1'b1 ),  // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata(STA_1),    // input wire [23 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid(div_flag),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(m_axis_dout_tdata)            // output wire [47 : 0] m_axis_dout_tdata
);

//取出除法的结果
always @(posedge clk_60m)
begin
	if(!cal_en)
		begin
			yushu <= 'd0;
			shang <= 'd0;
		end
	else 
		begin
			yushu <= m_axis_dout_tdata[23:0];//余数
			shang <= m_axis_dout_tdata[47:24];//商
		end

end


/***********查找朿大N***********/
always @ (posedge clk_60m)
begin
	if(!cal_en)
		count <= 'd0;
	else
		count <= count + 1'b1;
end

//查找最大的长短窗的比值对应的位置
always @ (posedge clk_60m)
begin
	if(!cal_en)
		begin
			mcount <= 'd0;
			shang_max <= 'd0;
			yushu_max <= 'd0;
		end
	else
		begin
			if((shang > shang_max && shang != 24'hffffff) || (shang == shang_max && yushu > yushu_max && shang != 24'hffffff))
			begin
				shang_max <= shang;
				yushu_max <= yushu ;
				mcount <= count;
			end
			
			
		end
end

endmodule

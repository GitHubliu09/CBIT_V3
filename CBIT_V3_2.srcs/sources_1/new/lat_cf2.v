`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 第4种特征函数：使用了两个点
//  CF(i) = abs(signal(i + 1) - signal(i));
// 长窗：75 短窗：35
//////////////////////////////////////////////////////////////////////////////////


module lat_cf2(
	input	[15:0]	data_r,//adc采集的数据（偏移二进制码）从ram里面取出来
	input		collect_once,//使能信号,1个周期即可
	input		clk_60m,//时钟60MHz 工作周期16.66ns
	input		rst,
	
	output	[13:0]	data_time,// data_time = data_arrive + DELAY_TIME
	output	[15:0]	add_r,//读ram地址
	output	wire	en_read,//读ram使能
	output	reg	CAL_END//计算完成标志
);

parameter			DELAY_TIME = 16'd0;//根据采集的时钟设置延迟时间
parameter 			DATA_LEN = 12'd1999;

reg				cal_en;
reg				cal_en_dly;
reg	signed	[14:0]		data_i,data_i1;
reg		[2:0]		collect_once_rcd = 3'b000;//接受采集完成的信号
reg		[15:0]		r_addr;//读ram的地址


reg		[14:0]		cf_t,cf;//特征函数
//长窗内求和的元素
reg		[14:0]		cf_Ldata_dly1,cf_Ldata_dly2,cf_Ldata_dly3,cf_Ldata_dly4,cf_Ldata_dly5;
reg		[14:0]		cf_Ldata_dly6,cf_Ldata_dly7,cf_Ldata_dly8,cf_Ldata_dly9,cf_Ldata_dly10;
reg		[14:0]		cf_Ldata_dly11,cf_Ldata_dly12,cf_Ldata_dly13,cf_Ldata_dly14,cf_Ldata_dly15;
reg		[14:0]		cf_Ldata_dly16,cf_Ldata_dly17,cf_Ldata_dly18,cf_Ldata_dly19,cf_Ldata_dly20;
reg		[14:0]		cf_Ldata_dly21,cf_Ldata_dly22,cf_Ldata_dly23,cf_Ldata_dly24,cf_Ldata_dly25;
reg		[14:0]		cf_Ldata_dly26,cf_Ldata_dly27,cf_Ldata_dly28,cf_Ldata_dly29,cf_Ldata_dly30;
reg		[14:0]		cf_Ldata_dly31,cf_Ldata_dly32,cf_Ldata_dly33,cf_Ldata_dly34,cf_Ldata_dly35;
reg		[14:0]		cf_Ldata_dly36,cf_Ldata_dly37,cf_Ldata_dly38,cf_Ldata_dly39,cf_Ldata_dly40;
reg		[14:0]		cf_Ldata_dly41,cf_Ldata_dly42,cf_Ldata_dly43,cf_Ldata_dly44,cf_Ldata_dly45;
reg		[14:0]		cf_Ldata_dly46,cf_Ldata_dly47,cf_Ldata_dly48,cf_Ldata_dly49,cf_Ldata_dly50;
reg		[14:0]		cf_Ldata_dly51,cf_Ldata_dly52,cf_Ldata_dly53,cf_Ldata_dly54,cf_Ldata_dly55;
reg		[14:0]		cf_Ldata_dly56,cf_Ldata_dly57,cf_Ldata_dly58,cf_Ldata_dly59,cf_Ldata_dly60;
reg		[14:0]		cf_Ldata_dly61,cf_Ldata_dly62,cf_Ldata_dly63,cf_Ldata_dly64,cf_Ldata_dly65;
reg		[14:0]		cf_Ldata_dly66,cf_Ldata_dly67,cf_Ldata_dly68,cf_Ldata_dly69,cf_Ldata_dly70;


//短窗内求和的元素
reg		[14:0]		cf_Sdata_dly1,cf_Sdata_dly2,cf_Sdata_dly3,cf_Sdata_dly4,cf_Sdata_dly5;
reg		[14:0]		cf_Sdata_dly6,cf_Sdata_dly7,cf_Sdata_dly8,cf_Sdata_dly9,cf_Sdata_dly10;
reg		[14:0]		cf_Sdata_dly11,cf_Sdata_dly12,cf_Sdata_dly13,cf_Sdata_dly14,cf_Sdata_dly15;
reg		[14:0]		cf_Sdata_dly16,cf_Sdata_dly17,cf_Sdata_dly18,cf_Sdata_dly19,cf_Sdata_dly20;
reg		[14:0]		cf_Sdata_dly21,cf_Sdata_dly22,cf_Sdata_dly23,cf_Sdata_dly24,cf_Sdata_dly25;
reg		[14:0]		cf_Sdata_dly26,cf_Sdata_dly27,cf_Sdata_dly28,cf_Sdata_dly29,cf_Sdata_dly30;
reg		[14:0]		cf_Sdata_dly31,cf_Sdata_dly32,cf_Sdata_dly33,cf_Sdata_dly34,cf_Sdata_dly35;


reg		[20:0]		LTA; // 4000*80 是19位二进制
reg		[20:0]		STA;
reg		[20:0]		LTA_1;
reg		[20:0]		STA_1;
reg		[7:0]		N;             //************
reg		[7:0]		N_max;
reg		[12:0]		count;
reg		[12:0]		mcount;
reg		[24:0]		yushu;
reg		[24:0]		shang;
reg		[24:0]		yushu_max;
reg		[24:0]		shang_max;

//wire
wire				div_flag;
wire		[47:0]		m_axis_dout_tdata;

assign 	add_r = r_addr;
assign	en_read = (add_r <= DATA_LEN)?cal_en : 1'd0;//计算开始使能信号作为读ram使能
assign	data_time = mcount + DELAY_TIME - 7'd65;




always @(posedge clk_60m)//保存传递过来的 collect_once 信号
begin
	collect_once_rcd <= {collect_once_rcd[1:0],collect_once};	
end

//产生计算使能信号
always @(posedge clk_60m or posedge rst )
begin
	if(rst == 1'b1)
		cal_en <= 1'b0;
	else if(collect_once_rcd[2:1] == 2'b01)//检测到collect_once信号的上升沿
		cal_en <= 1'b1;
	else if(r_addr > DATA_LEN+ 7'd36)//计算完成
		cal_en <= 1'b0;
end

		
//计算结束信号的产生
always @(posedge clk_60m or posedge rst)
begin
	if(rst == 1'b1)
		CAL_END <= 1'b0;
	else if(r_addr >= DATA_LEN + 7'd31 && r_addr <= DATA_LEN + 7'd36)//数据长度加上延时周期
		CAL_END <= 1'b1;
	else
		CAL_END <= 1'b0;

end

//产生读ram地址
always @(posedge clk_60m or posedge rst)
	if(rst == 1'b1)
		r_addr <= 'd0;
	else if(cal_en == 1'b1)
		r_addr <= r_addr + 1'b1;
	else 
		r_addr <= 'd0;
		
		
	
//使能信号延迟一拍和ram读出的数据对齐
always @(posedge clk_60m) 
begin
	cal_en_dly <= cal_en;
end


//读出来的数据变成有符号数,数据存进去的时候经过 00data 的扩展为16bit
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		data_i1 <= 15'h00000;
	else
		begin
			//offset binary 转换成有符号数补码，并把数据扩展一位防止计算溢出
			if(data_r[13] == 0)//表示负数
				data_i1 <= {2'b11,data_r[12:0]}  ;//变成负数的补码
			else
				data_i1 <= {2'b00,data_r[12:0]}  ;//变成正数的补码
		end
end

always @(posedge clk_60m)
begin

	data_i <= data_i1; //延时一个周期作为第i个点，data_i1 作为第i+1个点

end 

// 特征函数的cf_t的计算
always @(posedge clk_60m)
begin
	if(!cal_en_dly)
		cf <= 'd0;
	else 		
		cf_t <= data_i1 - data_i;		
end 	

//特征函数
always @(posedge clk_60m)
begin
	if(!cal_en_dly)
		cf <= 'd0;
	else if(cf_t[14] == 1'b0)//正数不变	
		cf <= cf_t;
	else //最高位是1，表示为负数
		cf <= {1'b0,(~cf_t[13:0] + 1'b1)};//负数补码变成正数			
end 

			
/***********构造长/短窗***********/
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		begin                                                  
			cf_Ldata_dly1  <= 14'd0; cf_Ldata_dly26 <= 14'd0; cf_Ldata_dly51 <= 14'd0;
			cf_Ldata_dly2  <= 14'd0; cf_Ldata_dly27 <= 14'd0; cf_Ldata_dly52 <= 14'd0;
			cf_Ldata_dly3  <= 14'd0; cf_Ldata_dly28 <= 14'd0; cf_Ldata_dly53 <= 14'd0;
			cf_Ldata_dly4  <= 14'd0; cf_Ldata_dly29 <= 14'd0; cf_Ldata_dly54 <= 14'd0;
			cf_Ldata_dly5  <= 14'd0; cf_Ldata_dly30 <= 14'd0; cf_Ldata_dly55 <= 14'd0;
			cf_Ldata_dly6  <= 14'd0; cf_Ldata_dly31 <= 14'd0; cf_Ldata_dly56 <= 14'd0;
			cf_Ldata_dly7  <= 14'd0; cf_Ldata_dly32 <= 14'd0; cf_Ldata_dly57 <= 14'd0;
			cf_Ldata_dly8  <= 14'd0; cf_Ldata_dly33 <= 14'd0; cf_Ldata_dly58 <= 14'd0;
			cf_Ldata_dly9  <= 14'd0; cf_Ldata_dly34 <= 14'd0; cf_Ldata_dly59 <= 14'd0;
			cf_Ldata_dly10 <= 14'd0; cf_Ldata_dly35 <= 14'd0; cf_Ldata_dly60 <= 14'd0;
			cf_Ldata_dly11 <= 14'd0; cf_Ldata_dly36 <= 14'd0; cf_Ldata_dly61 <= 14'd0;
			cf_Ldata_dly12 <= 14'd0; cf_Ldata_dly37 <= 14'd0; cf_Ldata_dly62 <= 14'd0;
			cf_Ldata_dly13 <= 14'd0; cf_Ldata_dly38 <= 14'd0; cf_Ldata_dly63 <= 14'd0;
			cf_Ldata_dly14 <= 14'd0; cf_Ldata_dly39 <= 14'd0; cf_Ldata_dly64 <= 14'd0;
			cf_Ldata_dly15 <= 14'd0; cf_Ldata_dly40 <= 14'd0; cf_Ldata_dly65 <= 14'd0;
			cf_Ldata_dly16 <= 14'd0; cf_Ldata_dly41 <= 14'd0; cf_Ldata_dly66 <= 14'd0;
			cf_Ldata_dly17 <= 14'd0; cf_Ldata_dly42 <= 14'd0; cf_Ldata_dly67 <= 14'd0;
			cf_Ldata_dly18 <= 14'd0; cf_Ldata_dly43 <= 14'd0; cf_Ldata_dly68 <= 14'd0;
			cf_Ldata_dly19 <= 14'd0; cf_Ldata_dly44 <= 14'd0; cf_Ldata_dly69 <= 14'd0;
			cf_Ldata_dly20 <= 14'd0; cf_Ldata_dly45 <= 14'd0; cf_Ldata_dly70 <= 14'd0;
			cf_Ldata_dly21 <= 14'd0; cf_Ldata_dly46 <= 14'd0; 
			cf_Ldata_dly22 <= 14'd0; cf_Ldata_dly47 <= 14'd0; 
			cf_Ldata_dly23 <= 14'd0; cf_Ldata_dly48 <= 14'd0; 
			cf_Ldata_dly24 <= 14'd0; cf_Ldata_dly49 <= 14'd0; 
			cf_Ldata_dly25 <= 14'd0; cf_Ldata_dly50 <= 14'd0; 
					
			cf_Sdata_dly1  <= 14'd0; cf_Sdata_dly2  <= 14'd0; cf_Sdata_dly3  <= 14'd0;
			cf_Sdata_dly4  <= 14'd0; cf_Sdata_dly5  <= 14'd0; cf_Sdata_dly6  <= 14'd0;
			cf_Sdata_dly7  <= 14'd0; cf_Sdata_dly8  <= 14'd0; cf_Sdata_dly9  <= 14'd0;
			cf_Sdata_dly10 <= 14'd0; cf_Sdata_dly11 <= 14'd0; cf_Sdata_dly12 <= 14'd0;
			cf_Sdata_dly13 <= 14'd0; cf_Sdata_dly14 <= 14'd0; cf_Sdata_dly15 <= 14'd0;
			cf_Sdata_dly16 <= 14'd0; cf_Sdata_dly17 <= 14'd0; cf_Sdata_dly18 <= 14'd0;
			cf_Sdata_dly19 <= 14'd0; cf_Sdata_dly20 <= 14'd0; cf_Sdata_dly21 <= 14'd0;
			cf_Sdata_dly22 <= 14'd0; cf_Sdata_dly23 <= 14'd0; cf_Sdata_dly24 <= 14'd0;
			cf_Sdata_dly25 <= 14'd0; cf_Sdata_dly26 <= 14'd0; cf_Sdata_dly27 <= 14'd0;
			cf_Sdata_dly28 <= 14'd0; cf_Sdata_dly29 <= 14'd0; cf_Sdata_dly30 <= 14'd0;
			cf_Sdata_dly31 <= 14'd0; cf_Sdata_dly32 <= 14'd0; cf_Sdata_dly33 <= 14'd0;
			cf_Sdata_dly34 <= 14'd0; cf_Sdata_dly35 <= 14'd0;
			
			
			
		end
	else
		begin
			cf_Sdata_dly1 <= cf; cf_Sdata_dly2 <= cf_Sdata_dly1; cf_Sdata_dly3 <= cf_Sdata_dly2;
		        cf_Sdata_dly4 <= cf_Sdata_dly3; cf_Sdata_dly5 <= cf_Sdata_dly4; cf_Sdata_dly6 <= cf_Sdata_dly5;
		        cf_Sdata_dly7 <= cf_Sdata_dly6; cf_Sdata_dly8 <= cf_Sdata_dly7; cf_Sdata_dly9 <= cf_Sdata_dly8;
		        cf_Sdata_dly10 <= cf_Sdata_dly9; cf_Sdata_dly11 <= cf_Sdata_dly10; cf_Sdata_dly12 <= cf_Sdata_dly11;
		        cf_Sdata_dly13 <= cf_Sdata_dly12; cf_Sdata_dly14 <= cf_Sdata_dly13; cf_Sdata_dly15 <= cf_Sdata_dly14;
		        cf_Sdata_dly16 <= cf_Sdata_dly15; cf_Sdata_dly17 <= cf_Sdata_dly16; cf_Sdata_dly18 <= cf_Sdata_dly17;
		        cf_Sdata_dly19 <= cf_Sdata_dly18; cf_Sdata_dly20 <= cf_Sdata_dly19; cf_Sdata_dly21 <= cf_Sdata_dly20;
		        cf_Sdata_dly22 <= cf_Sdata_dly21; cf_Sdata_dly23 <= cf_Sdata_dly22; cf_Sdata_dly24 <= cf_Sdata_dly23;
		        cf_Sdata_dly25 <= cf_Sdata_dly24; cf_Sdata_dly26 <= cf_Sdata_dly25; cf_Sdata_dly27 <= cf_Sdata_dly26;
		        cf_Sdata_dly28 <= cf_Sdata_dly27; cf_Sdata_dly29 <= cf_Sdata_dly28; cf_Sdata_dly30 <= cf_Sdata_dly29;
		        cf_Sdata_dly31 <= cf_Sdata_dly30; cf_Sdata_dly32 <= cf_Sdata_dly31; cf_Sdata_dly33 <= cf_Sdata_dly32;
		        cf_Sdata_dly34 <= cf_Sdata_dly33; cf_Sdata_dly35 <= cf_Sdata_dly34;
		//长窗
			cf_Ldata_dly1 <= cf_Sdata_dly35; cf_Ldata_dly2 <= cf_Ldata_dly1; cf_Ldata_dly3 <= cf_Ldata_dly2;
			cf_Ldata_dly4 <= cf_Ldata_dly3; cf_Ldata_dly5 <= cf_Ldata_dly4; cf_Ldata_dly6 <= cf_Ldata_dly5;
			cf_Ldata_dly7 <= cf_Ldata_dly6; cf_Ldata_dly8 <= cf_Ldata_dly7; cf_Ldata_dly9 <= cf_Ldata_dly8;
			cf_Ldata_dly10 <= cf_Ldata_dly9; cf_Ldata_dly11 <= cf_Ldata_dly10; cf_Ldata_dly12 <= cf_Ldata_dly11;
		        cf_Ldata_dly13 <= cf_Ldata_dly12; cf_Ldata_dly14 <= cf_Ldata_dly13; cf_Ldata_dly15 <= cf_Ldata_dly14;
		        cf_Ldata_dly16 <= cf_Ldata_dly15; cf_Ldata_dly17 <= cf_Ldata_dly16; cf_Ldata_dly18 <= cf_Ldata_dly17;
		        cf_Ldata_dly19 <= cf_Ldata_dly18; cf_Ldata_dly20 <= cf_Ldata_dly19; cf_Ldata_dly21 <= cf_Ldata_dly20;
		        cf_Ldata_dly22 <= cf_Ldata_dly21; cf_Ldata_dly23 <= cf_Ldata_dly22; cf_Ldata_dly24 <= cf_Ldata_dly23;
		        cf_Ldata_dly25 <= cf_Ldata_dly24; cf_Ldata_dly26 <= cf_Ldata_dly25; cf_Ldata_dly27 <= cf_Ldata_dly26;
		        cf_Ldata_dly28 <= cf_Ldata_dly27; cf_Ldata_dly29 <= cf_Ldata_dly28; cf_Ldata_dly30 <= cf_Ldata_dly29;
		        cf_Ldata_dly31 <= cf_Ldata_dly30; cf_Ldata_dly32 <= cf_Ldata_dly31; cf_Ldata_dly33 <= cf_Ldata_dly32;
		        cf_Ldata_dly34 <= cf_Ldata_dly33; cf_Ldata_dly35 <= cf_Ldata_dly34;
			cf_Ldata_dly36 <= cf_Ldata_dly35; cf_Ldata_dly37 <= cf_Ldata_dly36; cf_Ldata_dly38 <= cf_Ldata_dly37;
			cf_Ldata_dly39 <= cf_Ldata_dly38; cf_Ldata_dly40 <= cf_Ldata_dly39; cf_Ldata_dly41 <= cf_Ldata_dly40;
			cf_Ldata_dly42 <= cf_Ldata_dly41; cf_Ldata_dly43 <= cf_Ldata_dly42; cf_Ldata_dly44 <= cf_Ldata_dly43;
			cf_Ldata_dly45 <= cf_Ldata_dly44; cf_Ldata_dly46 <= cf_Ldata_dly45; cf_Ldata_dly47 <= cf_Ldata_dly46;
			cf_Ldata_dly48 <= cf_Ldata_dly47; cf_Ldata_dly49 <= cf_Ldata_dly48; cf_Ldata_dly50 <= cf_Ldata_dly49;
			cf_Ldata_dly51 <= cf_Ldata_dly50; cf_Ldata_dly52 <= cf_Ldata_dly51; cf_Ldata_dly53 <= cf_Ldata_dly52;
			cf_Ldata_dly54 <= cf_Ldata_dly53; cf_Ldata_dly55 <= cf_Ldata_dly54; cf_Ldata_dly56 <= cf_Ldata_dly55;
			cf_Ldata_dly57 <= cf_Ldata_dly56; cf_Ldata_dly58 <= cf_Ldata_dly57; cf_Ldata_dly59 <= cf_Ldata_dly58;
			cf_Ldata_dly60 <= cf_Ldata_dly59; cf_Ldata_dly61 <= cf_Ldata_dly60;
			cf_Ldata_dly62 <= cf_Ldata_dly61; cf_Ldata_dly63 <= cf_Ldata_dly62; cf_Ldata_dly64 <= cf_Ldata_dly63;
			cf_Ldata_dly65 <= cf_Ldata_dly64; cf_Ldata_dly66 <= cf_Ldata_dly65; cf_Ldata_dly67 <= cf_Ldata_dly66;
			cf_Ldata_dly68 <= cf_Ldata_dly67; cf_Ldata_dly69 <= cf_Ldata_dly68; cf_Ldata_dly70 <= cf_Ldata_dly69;
			
			
		end
end

/***********计算STA 、LTA***********/
always @ (posedge clk_60m)
begin
	if(!(cal_en_dly && add_r >= 110))//长窗70 + 短窗35 + 计算cf的5个周期的延迟
		begin
			STA <= 'd0;
			LTA <= 'd0;
		end
	else
		begin
			LTA <=cf_Ldata_dly1 +cf_Ldata_dly2 +cf_Ldata_dly3 +cf_Ldata_dly4 +cf_Ldata_dly5 +cf_Ldata_dly6 +cf_Ldata_dly7 +
					 cf_Ldata_dly8 +cf_Ldata_dly9 +cf_Ldata_dly10+cf_Ldata_dly11+cf_Ldata_dly12+cf_Ldata_dly13+cf_Ldata_dly14+
					 cf_Ldata_dly15+cf_Ldata_dly16+cf_Ldata_dly17+cf_Ldata_dly18+cf_Ldata_dly19+cf_Ldata_dly20+cf_Ldata_dly21+cf_Ldata_dly22+cf_Ldata_dly23+cf_Ldata_dly24+cf_Ldata_dly25 + cf_Ldata_dly26 + cf_Ldata_dly27 + cf_Ldata_dly28 + cf_Ldata_dly29 +
					 cf_Ldata_dly30  + cf_Ldata_dly31 + cf_Ldata_dly32 + cf_Ldata_dly33 + cf_Ldata_dly34 +
					 cf_Ldata_dly35  + cf_Ldata_dly36 + cf_Ldata_dly37 + cf_Ldata_dly38 + cf_Ldata_dly39 +
					 cf_Ldata_dly40  + cf_Ldata_dly41 + cf_Ldata_dly42 + cf_Ldata_dly43 + cf_Ldata_dly44 +
					 cf_Ldata_dly45  + cf_Ldata_dly46 + cf_Ldata_dly47 + cf_Ldata_dly48 + cf_Ldata_dly49 +
					 cf_Ldata_dly50  + cf_Ldata_dly51 + cf_Ldata_dly52 + cf_Ldata_dly53 + cf_Ldata_dly54 +
					 cf_Ldata_dly55  + cf_Ldata_dly56 + cf_Ldata_dly57 + cf_Ldata_dly58 + cf_Ldata_dly59 +
					 cf_Ldata_dly60  + cf_Ldata_dly61 + cf_Ldata_dly62 + cf_Ldata_dly63 + cf_Ldata_dly64 +
					 cf_Ldata_dly65  + cf_Ldata_dly66 + cf_Ldata_dly67 + cf_Ldata_dly68 + cf_Ldata_dly69 +
					 cf_Ldata_dly70;
			STA <= cf_Sdata_dly1 + cf_Sdata_dly2 + cf_Sdata_dly3 + cf_Sdata_dly4 + cf_Sdata_dly5 + cf_Sdata_dly6 + 
				cf_Sdata_dly7 + cf_Sdata_dly8 + cf_Sdata_dly9 + cf_Sdata_dly10 + cf_Sdata_dly11 + cf_Sdata_dly12+ 
				cf_Sdata_dly13 + cf_Sdata_dly14 + cf_Sdata_dly15 + cf_Sdata_dly16 + cf_Sdata_dly17 + cf_Sdata_dly18+ 
				cf_Sdata_dly19 + cf_Sdata_dly20 + cf_Sdata_dly21 + cf_Sdata_dly22 + cf_Sdata_dly23 + cf_Sdata_dly24 + 
				cf_Sdata_dly25 + cf_Sdata_dly26 + cf_Sdata_dly27 + cf_Sdata_dly28 + cf_Sdata_dly29 + cf_Sdata_dly30 + 
				cf_Sdata_dly31 + cf_Sdata_dly32 + cf_Sdata_dly33 + cf_Sdata_dly34 + cf_Sdata_dly35;
		end
end


//窗长为70、35时 长短窗的比值可以变为 短窗*2/长窗，即(sta + sta)/lta
always@(posedge clk_60m )
begin
	if(!(cal_en_dly && cf_Ldata_dly70)) begin
		LTA_1 <=  'd0;
		STA_1 <= 'd0;
		
	end
	else begin
		LTA_1 <= LTA;
//		STA_1 <= STA + STA;
//        STA_1 <= {STA[20:1],1'b0};
            STA_1 <= STA << 1;
	end
end


//除法，计算长短窗的比值 24位无符号数除法
div_gen_1 your_instance_name (
  .aclk(clk_60m),                                      // input wire aclk
  .s_axis_divisor_tvalid(cal_en),    // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata({2'b00,LTA_1}),      // input wire [23 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(cal_en),  // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata({2'b00,STA_1}),    // input wire [23 : 0] s_axis_dividend_tdata
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



/***********查找最大N***********/
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
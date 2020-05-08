`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//算法延迟7周期
// 第二种特征函数：使用了两个点
//CF = signal(i + 1)*signal(i+1) + (signal(i+1)-signal(i))*(signal(i+1)-signal(i))
// 即CF = 2*signal(i + 1 ) * signal(i + 1) + signal(i) * signal - 2 * signal(i) * signal(i + 1)
//////////////////////////////////////////////////////////////////////////////////


module lat_cf2_2t(
	input	[15:0]	data_r,//adc采集的数据（偏移二进制码）从ram里面取出来
	input		collect_once,//使能信号,1个周期即可
	input		clk_60m,//时钟60MHz 工作周期16.66ns
	input		rst,
	input [13:0]collect_num,//collect number
	
	output	[13:0]	data_time,// data_time = data_arrive + DELAY_TIME
	output	[15:0]	add_r,//读ram地址
	output	wire	en_read,//读ram使能
	output	reg	CAL_END//计算完成标志
);

parameter			DELAY_TIME = 16'd0;//延时1us时设置为20，20M时钟
parameter 			DATA_LEN = 12'd4000;

reg				cal_en;
reg				cal_en_dly;
reg		[15:0]		data_i,data_i1;
reg		[2:0]		collect_once_rcd = 3'b000;
reg		[15:0]		r_addr;
reg		[12:0]		data_conuter;
reg		[31:0]		data_squ22,data_squ11,data_squ12;//数据的平方
reg		[32:0]		cf;//特征函数

reg		[32:0]		cf_Ldata_dly1,cf_Ldata_dly2,cf_Ldata_dly3,cf_Ldata_dly4,cf_Ldata_dly5;
reg		[32:0]		cf_Ldata_dly6,cf_Ldata_dly7,cf_Ldata_dly8,cf_Ldata_dly9,cf_Ldata_dly10;
reg		[32:0]		cf_Ldata_dly11,cf_Ldata_dly12,cf_Ldata_dly13,cf_Ldata_dly14,cf_Ldata_dly15;
reg		[32:0]		cf_Ldata_dly16,cf_Ldata_dly17,cf_Ldata_dly18,cf_Ldata_dly19,cf_Ldata_dly20;
reg		[32:0]		cf_Ldata_dly21,cf_Ldata_dly22,cf_Ldata_dly23,cf_Ldata_dly24,cf_Ldata_dly25;
reg		[32:0]		cf_Sdata_dly1,cf_Sdata_dly2,cf_Sdata_dly3;
reg		[34:0]		LTA,LTA_t1,LTA_t2,LTA_t3,LTA_t4,LTA_t5,LTA_t6,LTA_t7,LTA_t8,LTA_t9,LTA_t10,LTA_t11,LTA_t12;
reg		[34:0]		STA,STA_t1,STA_t2;
reg		[35:0]		LTA_1;
reg		[35:0]		STA_1;
reg		[7:0]		N;             //************
reg		[7:0]		N_max;
reg		[12:0]		count;
reg		[12:0]		mcount;
reg		[39:0]		yushu;
reg		[39:0]		shang;
reg		[39:0]		yushu_max;
reg		[39:0]		shang_max;

//wire
wire				div_flag;
wire		[79:0]		m_axis_dout_tdata;

assign add_r = r_addr;
assign	en_read = (add_r <= collect_num)?cal_en : 1'd0;//计算开始使能信号作为读ram使能
assign	data_time = mcount + DELAY_TIME ; // - 6'd36-2'd3
/*计算完特征函数后算法延迟 : 读ram1个周期，数据变成补码1个周期，
获得另一个用于计算的数据1个周期，数据平方1个周期，计算cf1个周期，cf 移入窗内1个周期 ，窗内求和1个周期，
乘法1个周期，除法28个周期，取出商加余数1个周期，最后判断加输出不占延迟。
一共37个周期。
 短窗的窗长：3 所以最后的结果减46 + 3*/


always @(posedge clk_60m)//检测采集完成信号的沿变化
	collect_once_rcd <= {collect_once_rcd[1:0],collect_once};
	


//产生计算使能信号
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
	else if(data_conuter == collect_num + 6'd48)//数据长度加上延时周期
		CAL_END <= 1'b1;
	else
		CAL_END <= 1'b0;



//产生读ram地址
always @(posedge clk_60m or posedge rst)
	if(rst == 1'b1)
		r_addr <= 'd0;
	else if(cal_en == 1'b1)
		r_addr <= r_addr + 1'b1;
	else 
		r_addr <= 'd0;
		
		
	
//使能信号延迟一拍和ram读出的数据对齐
always @(posedge clk_60m) begin
	cal_en_dly <= cal_en;
end


//读出来的数据变成有符号数
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		data_i1 <= 16'h00000;
	else
		begin
			//offset binary 转换成有符号数补码
			if(data_r[15] == 0)//表示负数
				data_i1 <= {1,data_r[14:0]}  ;//变成负数的补码
			else
				data_i1 <= {0,data_r[14:0]}  ;//正数的补码形式
		end
end

always @(posedge clk_60m)
	data_i <= data_i1;//延时一个周期作为第i个点，data_i1 作为第i+1个点

//产生计算特征函数的数据
always @(posedge clk_60m ) begin
	if(!cal_en_dly) begin
		data_squ22 <= 31'h00000;
		data_squ11 <= 31'h00000;
		data_squ12 <= 31'h00000;
	end
	else begin
		data_squ12 <= data_i * data_i1;
		data_squ22 <= data_i1 * data_i1;
		data_squ11 <= data_i * data_i;
	end
	
end

// 特征函数的计算
always @(posedge clk_60m)
	if(!cal_en_dly)
		cf <= 'd0;
	else
		cf <= data_squ22 + data_squ22 + data_squ11 - data_squ12 - data_squ12;
		
				
/***********构造长/短窗***********/
always @ (posedge clk_60m)
begin
	if(!cal_en_dly)
		begin
			cf_Ldata_dly1 <= 'd0;
			cf_Ldata_dly2 <= 'd0;
			cf_Ldata_dly3 <= 'd0;
			cf_Ldata_dly4 <= 'd0;
			cf_Ldata_dly5 <= 'd0;
			cf_Ldata_dly6 <= 'd0;
			cf_Ldata_dly7 <= 'd0;
			cf_Ldata_dly8 <= 'd0;
			cf_Ldata_dly9 <= 'd0;
			cf_Ldata_dly10 <= 'd00;
			cf_Ldata_dly11 <= 'd00;
			cf_Ldata_dly12 <= 'd00;
			cf_Ldata_dly13 <= 'd00;
			cf_Ldata_dly14 <= 'd00;
			cf_Ldata_dly15 <= 'd00;
			cf_Ldata_dly16 <= 'd00;
			cf_Ldata_dly17 <= 'd00;
			cf_Ldata_dly18 <= 'd00;
			cf_Ldata_dly19 <= 'd00;
			cf_Ldata_dly20 <= 'd00;
			cf_Ldata_dly21 <= 'd00;
			cf_Ldata_dly22 <= 'd00;
			cf_Ldata_dly23 <= 'd00;
			cf_Ldata_dly24 <= 'd00;
			cf_Ldata_dly25 <= 'd00;
			cf_Sdata_dly1 <= 'd0;
			cf_Sdata_dly2 <= 'd0;
			cf_Sdata_dly3 <= 'd0;
		end
	else
		begin
			cf_Sdata_dly1 <= cf;//构造短窗:窗长3
			cf_Sdata_dly2 <= cf_Sdata_dly1;
			cf_Sdata_dly3 <= cf_Sdata_dly2;
			cf_Ldata_dly1 <= cf_Sdata_dly3;//构造长窗:窗长25
			cf_Ldata_dly2 <= cf_Ldata_dly1;
			cf_Ldata_dly3 <= cf_Ldata_dly2;
			cf_Ldata_dly4 <= cf_Ldata_dly3;
			cf_Ldata_dly5 <= cf_Ldata_dly4;
			cf_Ldata_dly6 <= cf_Ldata_dly5;
			cf_Ldata_dly7 <= cf_Ldata_dly6;
			cf_Ldata_dly8 <= cf_Ldata_dly7;
			cf_Ldata_dly9 <= cf_Ldata_dly8;
			cf_Ldata_dly10 <= cf_Ldata_dly9;
			cf_Ldata_dly11 <= cf_Ldata_dly10;
			cf_Ldata_dly12 <= cf_Ldata_dly11;
			cf_Ldata_dly13 <= cf_Ldata_dly12;
			cf_Ldata_dly14 <= cf_Ldata_dly13;
			cf_Ldata_dly15 <= cf_Ldata_dly14;
			cf_Ldata_dly16 <= cf_Ldata_dly15;
			cf_Ldata_dly17 <= cf_Ldata_dly16;
			cf_Ldata_dly18 <= cf_Ldata_dly17;
			cf_Ldata_dly19 <= cf_Ldata_dly18;
			cf_Ldata_dly20 <= cf_Ldata_dly19;
			cf_Ldata_dly21 <= cf_Ldata_dly20;
			cf_Ldata_dly22 <= cf_Ldata_dly21;
			cf_Ldata_dly23 <= cf_Ldata_dly22;
			cf_Ldata_dly24 <= cf_Ldata_dly23;
			cf_Ldata_dly25 <= cf_Ldata_dly24;
		end
end

/***********计算STA/LTA***********/
always @ (posedge clk_60m or posedge rst)
begin
    if(rst)
    begin
            STA <= 'd0;
			LTA <= 'd0;
			LTA_t1 <= 'd0;
			LTA_t2 <= 'd0;
			LTA_t3 <= 'd0;
			LTA_t4 <= 'd0;
			LTA_t5 <= 'd0;
			LTA_t6 <= 'd0;
			LTA_t7 <= 'd0;
			LTA_t8 <= 'd0;
			LTA_t9 <= 'd0;
			LTA_t10 <= 'd0;
			LTA_t11 <= 'd0;
			LTA_t12 <= 'd0;
			STA_t1 <= 'd0;
			STA_t2 <= 'd0;
    end
    else
    begin
	if(!(cal_en_dly && cf_Ldata_dly25))
		begin
			STA <= 'd0;
			LTA <= 'd0;
			LTA_t1 <= 'd0;
			LTA_t2 <= 'd0;
			LTA_t3 <= 'd0;
			LTA_t4 <= 'd0;
			LTA_t5 <= 'd0;
			LTA_t6 <= 'd0;
			LTA_t7 <= 'd0;
			LTA_t8 <= 'd0;
			LTA_t9 <= 'd0;
			LTA_t10 <= 'd0;
			LTA_t11 <= 'd0;
			LTA_t12 <= 'd0;
			STA_t1 <= 'd0;
			STA_t2 <= 'd0;
			
			
		end
	else
		begin
			LTA_t1 <=cf_Ldata_dly1 +cf_Ldata_dly2 +cf_Ldata_dly3 ;
			LTA_t2 <= cf_Ldata_dly4 +cf_Ldata_dly5 + cf_Ldata_dly6;
			LTA_t3 <= cf_Ldata_dly7 + cf_Ldata_dly8 +cf_Ldata_dly9;
			LTA_t4 <= cf_Ldata_dly10 + cf_Ldata_dly11+cf_Ldata_dly12;
			LTA_t5 <= cf_Ldata_dly13+cf_Ldata_dly14+ cf_Ldata_dly15;
			LTA_t6 <= cf_Ldata_dly16+cf_Ldata_dly17+cf_Ldata_dly18;
			LTA_t7 <= cf_Ldata_dly19+cf_Ldata_dly20+cf_Ldata_dly21;
			LTA_t8 <= cf_Ldata_dly22+cf_Ldata_dly23+cf_Ldata_dly24;
			LTA_t9 <= cf_Ldata_dly25;
			LTA_t10 <= LTA_t1 + LTA_t2 + LTA_t3;
			LTA_t11 <= LTA_t4 + LTA_t5 + LTA_t6;
			LTA_t12 <= LTA_t7 + LTA_t8 + LTA_t9;
			LTA <= LTA_t10 + LTA_t11 + LTA_t12 ;
			STA_t1 <= cf_Sdata_dly1+cf_Sdata_dly2+cf_Sdata_dly3;
			STA_t2 <= STA_t1;
			STA <= STA_t2;
		end
		end
end


//特征函数除法转变成乘法，乘法的计算延迟小
always@(posedge clk_60m )
begin
	if(!(cal_en_dly && cf_Ldata_dly25)) begin
		LTA_1 <=  'd0;
		STA_1 <= 'd0;
		
	end
	else begin
		LTA_1 <= LTA*6'd3;
		STA_1 <= STA*6'd25;
	end
end


//除法，计算长短窗的比值
div_36by36 div2 (
  .aclk(clk_60m),                                      
  .s_axis_divisor_tvalid(cal_en ),    
  .s_axis_divisor_tdata(LTA_1),      
  .s_axis_dividend_tvalid(cal_en ),  
  .s_axis_dividend_tdata(STA_1),    
  .m_axis_dout_tvalid(div_flag),        
  .m_axis_dout_tdata(m_axis_dout_tdata) 
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
			yushu <= m_axis_dout_tdata[39:0];//余数
			shang <= m_axis_dout_tdata[79:40];//商
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
			if((shang > shang_max && shang != 40'hffffffffff) || (shang == shang_max && yushu > yushu_max && shang != 40'hffffffffff))
			begin
				shang_max <= shang;
				yushu_max <= yushu ;
				mcount <= count;
			end
			
			
		end
end


endmodule
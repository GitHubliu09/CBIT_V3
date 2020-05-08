`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 计算，从存ADC数据的那个RAM中取数据
//////////////////////////////////////////////////////////////////////////////////


module calculate(
    input clk,
    input clk_20m,
    input rst,
    output en_read,
    output [13:0] add_r,
    input [15:0] data_r,
    input [13:0]collect_num,
    input bodymark,
    input fire_once,
    input collect_once,
    input collect_achieve,
    input [7:0]sweep_num,//*********要上传的波形的位置
    output  reg sweep_en,//  *********************上传波形使能
    output  we_time,//(we_out)
    output reg [13:0]add_time,//(wadd_out)
    output [13:0]add_peak,
    output reg [15:0]data_time,
    output reg [15:0]data_peak,
//    output calculate_once,
    output calculate_achieve
    );
    
reg c_ach;
reg cl_t_ach , cl_ach1 , cl_ach2 ,cl_ach3,cl_ach4,cl_ach5,cl_ach6;
reg c_o_t,c_o1,c_o2,c_o3,c_o4,c_o5,c_o6;
reg we_peak;
reg we_t1,we_t2;

reg [15:0]data_r_t;
wire [15:0]data_time_t;
wire [13:0]acq_cnt;
reg [13:0]add_cnt;
reg [15:0]d_amp;
reg [15:0]a_time;
reg [15:0]a_amp;
reg [13:0]r_add_s;
reg [8:0]sweep_cnt = 9'd0;
reg [7:0]sweep_t;//***********sweep_t表示临时变量
reg [7:0]sweep_num1,sweep_num2;
reg sweep_change;
reg start_cal;
wire CAL_END;

/****************** useful parameter ***********************/
parameter over_zero = 16'd1;//when adc data > 16'd1 -> the first wave arrival

reg [2:0]state;
parameter IDLE = 3'b000;
parameter STARTCYCLE = 3'b001;
parameter STARTONCE = 3'b010;
parameter WAIT = 3'b011;
parameter CAL = 3'b100;
parameter WRITE = 3'b101;
parameter DONE = 3'b110;

parameter delay_time = 16'd20;//delay time 0.05us (20MHz)


assign acq_cnt = add_r;
assign add_peak = add_cnt;
assign calculate_achieve = cl_ach1 | cl_ach2 | cl_ach3 | cl_ach4 | cl_ach5 | cl_ach6;
assign we_time = we_t1 | we_t2;

always@(negedge clk , posedge rst)
begin
    if(rst)
    begin
        we_t1 <= 1'b0;
        we_t2 <= 1'b0;
        add_time <= 14'd0;
        data_time <= 8'd0;
        data_peak <= 12'd0;
    end
    else
    begin
        we_t1 <= we_peak;
        we_t2 <= we_t1;
        add_time <= add_cnt;
        data_time <= r_add_s;//到时
        data_peak <= d_amp;
    end
end

always@(posedge clk , posedge rst)
begin 
    if(rst)
    begin
        sweep_num1 <= 8'd0;
        sweep_num2 <= 8'd0;
        
        data_r_t <= 16'd0;
    end
    else
    begin
        sweep_num1 <= sweep_num;
        sweep_num2 <= sweep_num1;
        
        data_r_t <= data_r;
    end
end

always@(posedge clk, posedge rst)
begin
    if(rst)
    begin
        sweep_en <= 1'b0;
        sweep_cnt <= 9'd0;
        sweep_change <= 1'b0;
        sweep_t <= 8'd249;
    end
    else 
    begin
        sweep_t <= 8'd249 - sweep_num1;
        if(sweep_num1 != sweep_num2)
            sweep_change <= 1'b1;
        
        if(cl_ach1)//calculate_achieve
        begin
            if(sweep_change)
            begin
                sweep_cnt <= sweep_num1;
                sweep_change <= 1'b0;
            end
            else if(sweep_cnt > sweep_t)
                sweep_cnt <= sweep_cnt + sweep_num1 - 8'd250;
                //波形是从0->249组，由于fpga是并行执行的结构 不能让程序中上传波形的位置计数有大于249的时候 ，因此比较的数应该向上面这样设计
            else
                sweep_cnt <= sweep_cnt + sweep_num1;
        end
        
        if(sweep_num1 == 8'd0)
            sweep_en <= 1'b0;
        else
        if((add_cnt == sweep_cnt) && (acq_cnt == 14'd1 || acq_cnt == 14'd2 ))
            sweep_en <= 1'b1;
        else
            sweep_en <= 1'b0;
    end
end

always@(posedge clk , posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
//        acq_cnt <= 14'd0;
       c_ach <= 1'b0;
//       en_r <= 1'b0;
       cl_t_ach <= 1'b0;
       add_cnt <= 14'd0;
       we_peak <= 1'b0;
       c_o_t <= 1'b0;
       d_amp <= 16'd0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
//            if(collectmark)
                state <= STARTCYCLE;
        end
        
        STARTCYCLE:
        begin
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
            c_ach <= 1'b0;
//            acq_cnt <= 14'd0;
//            en_r <= 1'b0;
            we_peak <= 1'b0;
            cl_t_ach <= 1'b0;
            add_cnt <= 14'd0;
//            if(fire_once)
//            begin
                state <= WAIT;
//            end
        end
        
        STARTONCE:
        begin
//            acq_cnt <= 14'd0;
            we_peak <= 1'b0;
//            if(fire_once)
                state <= WAIT;
        end
        
        WAIT:
        begin
            if(collect_once == 1 && collect_achieve == 1)
            begin
                start_cal <= 1'b1;
                c_ach <= 1'b1;
                state <= CAL;
            end
            else if(collect_once == 1)
            begin
                start_cal <= 1'b1;
                state <= CAL;
            end
        end
        
        CAL:
        begin
        start_cal <= 1'b0;
        if(CAL_END)
        begin
            state <= WRITE;
            r_add_s <= data_time_t;
        end
        if(data_r_t > d_amp)
        begin
            d_amp <= data_r_t;
        end
        
//            en_r <= 1'b1;
//            we_peak <= 1'b0;
//            if(acq_cnt == collect_num)
//            begin
//                state <= WRITE;
//                acq_cnt <= 14'd0;
//            end
//            else
//                acq_cnt <= acq_cnt + 1'b1;
//            if(data_r > d_amp)
//            begin
//                d_amp <= data_r;
//                r_add_s <= acq_cnt;//这个是峰值对应的时间
//            end
        end
        
        WRITE:
        begin
            c_o_t<= 1'b1;
            we_peak <= 1'b1;
//            en_r <= 1'b0;
            state <= DONE;
        end
        
        DONE:
        begin
            c_o_t <= 1'b0;
//            en_r <= 1'b0;
            we_peak <= 1'b0;
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
             if(c_ach == 1)
            begin
                state <= STARTCYCLE;
                cl_t_ach <= 1'b1;
            end
            else
            begin
                state <= STARTONCE;
                add_cnt <= add_cnt + 1'b1;
            end
        end
        
        default:
        begin
            state <= IDLE;
        end
        endcase
    end
end

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cl_ach1 <= 1'b0;
        cl_ach2 <= 1'b0;
        cl_ach3 <= 1'b0;
        cl_ach4 <= 1'b0;
        cl_ach5 <= 1'b0;
        cl_ach6 <= 1'b0;
        c_o1 <= 1'b0;
        c_o2 <= 1'b0;
        c_o3 <= 1'b0;
        c_o4 <= 1'b0;
        c_o5 <= 1'b0;
        c_o6 <= 1'b0;
    end
    else
    begin
        cl_ach1 <= cl_t_ach;
        cl_ach2 <= cl_ach1;
        cl_ach3 <= cl_ach2;
        cl_ach4 <= cl_ach3;
        cl_ach5 <= cl_ach4;
        cl_ach6 <= cl_ach5;
        c_o1 <= c_o_t;
        c_o2 <= c_o1;
        c_o3 <= c_o2;
        c_o4 <= c_o3;
        c_o5 <= c_o4;
        c_o6 <= c_o5;
    end
end

////特征函数：绝对值    
//lat_w_interface lat_w_interface(
//	.data_r( data_r),//adc采集的数据（偏移二进制码）从ram里面取出来
//	.collect_once( start_cal),//使能信号,1个周期即可
//	.clk_60m(clk),//时钟20MHz 工作周期50ns
//	.rst(rst),
//	.data_time(data_time_t ),// data_time = data_arrive + DELAY_TIME
//	.add_r( add_r),//读ram地址
//	.en_read( en_read),//读ram使能
//	.CAL_END(CAL_END)//计算完成标志
//); 

//特征函数：第二种
lat_cf2 lat_cf2(
	.data_r( data_r),//adc采集的数据（偏移二进制码）从ram里面取出来
	.collect_once( start_cal),//使能信号,1个周期即可
	.clk_60m(clk),//时钟20MHz 工作周期50ns
	.rst(rst),
	.collect_num(collect_num),//collect number
	.data_time(data_time_t ),// data_time = data_arrive + DELAY_TIME
	.add_r( add_r),//读ram地址
	.en_read( en_read),//读ram使能
	.CAL_END(CAL_END)//计算完成标志
);
    
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 计算，从存ADC数据的那个RAM中取数据
//////////////////////////////////////////////////////////////////////////////////


module calculate(
    input clk,
    input clk_20m,
    input rst,
    output en_read,
    output [13:0] add_r,
    input [15:0] data_r,
    input [13:0]collect_num,
    input bodymark,
    input fire_once,
    input collect_once,
    input collect_achieve,
    input [7:0]sweep_num,//*********要上传的波形的位置
    output  reg sweep_en,//  *********************上传波形使能
    output  we_time,//(we_out)
    output reg [13:0]add_time,//(wadd_out)
    output [13:0]add_peak,
    output reg [15:0]data_time,
    output reg [15:0]data_peak,
//    output calculate_once,
    output calculate_achieve
    );
    
reg c_ach;
reg cl_t_ach , cl_ach1 , cl_ach2 ,cl_ach3,cl_ach4,cl_ach5,cl_ach6;
reg c_o_t,c_o1,c_o2,c_o3,c_o4,c_o5,c_o6;
reg we_peak;
reg we_t1,we_t2;

reg [15:0]data_r_t;
wire [15:0]data_time_t;
wire [13:0]acq_cnt;
reg [13:0]add_cnt;
reg [15:0]d_amp;
reg [15:0]a_time;
reg [15:0]a_amp;
reg [13:0]r_add_s;
reg [8:0]sweep_cnt = 9'd0;
reg [7:0]sweep_t;//***********sweep_t表示临时变量
reg [7:0]sweep_num1,sweep_num2;
reg sweep_change;
reg start_cal;
wire CAL_END;

/****************** useful parameter ***********************/
parameter over_zero = 16'd1;//when adc data > 16'd1 -> the first wave arrival

reg [2:0]state;
parameter IDLE = 3'b000;
parameter STARTCYCLE = 3'b001;
parameter STARTONCE = 3'b010;
parameter WAIT = 3'b011;
parameter CAL = 3'b100;
parameter WRITE = 3'b101;
parameter DONE = 3'b110;

parameter delay_time = 16'd20;//delay time 0.05us (20MHz)


assign acq_cnt = add_r;
assign add_peak = add_cnt;
assign calculate_achieve = cl_ach1 | cl_ach2 | cl_ach3 | cl_ach4 | cl_ach5 | cl_ach6;
assign we_time = we_t1 | we_t2;

always@(negedge clk , posedge rst)
begin
    if(rst)
    begin
        we_t1 <= 1'b0;
        we_t2 <= 1'b0;
        add_time <= 14'd0;
        data_time <= 8'd0;
        data_peak <= 12'd0;
    end
    else
    begin
        we_t1 <= we_peak;
        we_t2 <= we_t1;
        add_time <= add_cnt;
        data_time <= r_add_s;//到时
        data_peak <= d_amp;
    end
end

always@(posedge clk , posedge rst)
begin 
    if(rst)
    begin
        sweep_num1 <= 8'd0;
        sweep_num2 <= 8'd0;
        
        data_r_t <= 16'd0;
    end
    else
    begin
        sweep_num1 <= sweep_num;
        sweep_num2 <= sweep_num1;
        
        data_r_t <= data_r;
    end
end

always@(posedge clk, posedge rst)
begin
    if(rst)
    begin
        sweep_en <= 1'b0;
        sweep_cnt <= 9'd0;
        sweep_change <= 1'b0;
        sweep_t <= 8'd249;
    end
    else 
    begin
        sweep_t <= 8'd249 - sweep_num1;
        if(sweep_num1 != sweep_num2)
            sweep_change <= 1'b1;
        
        if(cl_ach1)//calculate_achieve
        begin
            if(sweep_change)
            begin
                sweep_cnt <= sweep_num1;
                sweep_change <= 1'b0;
            end
            else if(sweep_cnt > sweep_t)
                sweep_cnt <= sweep_cnt + sweep_num1 - 8'd250;
                //波形是从0->249组，由于fpga是并行执行的结构 不能让程序中上传波形的位置计数有大于249的时候 ，因此比较的数应该向上面这样设计
            else
                sweep_cnt <= sweep_cnt + sweep_num1;
        end
        
        if(sweep_num1 == 8'd0)
            sweep_en <= 1'b0;
        else
        if((add_cnt == sweep_cnt) && (acq_cnt == 14'd1 || acq_cnt == 14'd2 ))
            sweep_en <= 1'b1;
        else
            sweep_en <= 1'b0;
    end
end

always@(posedge clk , posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
//        acq_cnt <= 14'd0;
       c_ach <= 1'b0;
//       en_r <= 1'b0;
       cl_t_ach <= 1'b0;
       add_cnt <= 14'd0;
       we_peak <= 1'b0;
       c_o_t <= 1'b0;
       d_amp <= 16'd0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
//            if(collectmark)
                state <= STARTCYCLE;
        end
        
        STARTCYCLE:
        begin
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
            c_ach <= 1'b0;
//            acq_cnt <= 14'd0;
//            en_r <= 1'b0;
            we_peak <= 1'b0;
            cl_t_ach <= 1'b0;
            add_cnt <= 14'd0;
//            if(fire_once)
//            begin
                state <= WAIT;
//            end
        end
        
        STARTONCE:
        begin
//            acq_cnt <= 14'd0;
            we_peak <= 1'b0;
//            if(fire_once)
                state <= WAIT;
        end
        
        WAIT:
        begin
            if(collect_once == 1 && collect_achieve == 1)
            begin
                start_cal <= 1'b1;
                c_ach <= 1'b1;
                state <= CAL;
            end
            else if(collect_once == 1)
            begin
                start_cal <= 1'b1;
                state <= CAL;
            end
        end
        
        CAL:
        begin
        start_cal <= 1'b0;
        if(CAL_END)
        begin
            state <= WRITE;
            r_add_s <= data_time_t;
        end
        if(data_r_t > d_amp)
        begin
            d_amp <= data_r_t;
        end
        
//            en_r <= 1'b1;
//            we_peak <= 1'b0;
//            if(acq_cnt == collect_num)
//            begin
//                state <= WRITE;
//                acq_cnt <= 14'd0;
//            end
//            else
//                acq_cnt <= acq_cnt + 1'b1;
//            if(data_r > d_amp)
//            begin
//                d_amp <= data_r;
//                r_add_s <= acq_cnt;//这个是峰值对应的时间
//            end
        end
        
        WRITE:
        begin
            c_o_t<= 1'b1;
            we_peak <= 1'b1;
//            en_r <= 1'b0;
            state <= DONE;
        end
        
        DONE:
        begin
            c_o_t <= 1'b0;
//            en_r <= 1'b0;
            we_peak <= 1'b0;
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
             if(c_ach == 1)
            begin
                state <= STARTCYCLE;
                cl_t_ach <= 1'b1;
            end
            else
            begin
                state <= STARTONCE;
                add_cnt <= add_cnt + 1'b1;
            end
        end
        
        default:
        begin
            state <= IDLE;
        end
        endcase
    end
end

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cl_ach1 <= 1'b0;
        cl_ach2 <= 1'b0;
        cl_ach3 <= 1'b0;
        cl_ach4 <= 1'b0;
        cl_ach5 <= 1'b0;
        cl_ach6 <= 1'b0;
        c_o1 <= 1'b0;
        c_o2 <= 1'b0;
        c_o3 <= 1'b0;
        c_o4 <= 1'b0;
        c_o5 <= 1'b0;
        c_o6 <= 1'b0;
    end
    else
    begin
        cl_ach1 <= cl_t_ach;
        cl_ach2 <= cl_ach1;
        cl_ach3 <= cl_ach2;
        cl_ach4 <= cl_ach3;
        cl_ach5 <= cl_ach4;
        cl_ach6 <= cl_ach5;
        c_o1 <= c_o_t;
        c_o2 <= c_o1;
        c_o3 <= c_o2;
        c_o4 <= c_o3;
        c_o5 <= c_o4;
        c_o6 <= c_o5;
    end
end

////特征函数：绝对值    
//lat_w_interface lat_w_interface(
//	.data_r( data_r),//adc采集的数据（偏移二进制码）从ram里面取出来
//	.collect_once( start_cal),//使能信号,1个周期即可
//	.clk_60m(clk),//时钟20MHz 工作周期50ns
//	.rst(rst),
//	.data_time(data_time_t ),// data_time = data_arrive + DELAY_TIME
//	.add_r( add_r),//读ram地址
//	.en_read( en_read),//读ram使能
//	.CAL_END(CAL_END)//计算完成标志
//); 

//特征函数：第二种
lat_cf2 lat_cf2(
	.data_r( data_r),//adc采集的数据（偏移二进制码）从ram里面取出来
	.collect_once( start_cal),//使能信号,1个周期即可
	.clk_60m(clk),//时钟20MHz 工作周期50ns
	.rst(rst),
	.collect_num(collect_num),//collect number
	.data_time(data_time_t ),// data_time = data_arrive + DELAY_TIME
	.add_r( add_r),//读ram地址
	.en_read( en_read),//读ram使能
	.CAL_END(CAL_END)//计算完成标志
);
    
endmodule

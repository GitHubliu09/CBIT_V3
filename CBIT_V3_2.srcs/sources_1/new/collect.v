`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// adc work mode
// adc nap mode , 15mW , 100 clock cycles
// adc sleep mode , 1mW , 9ms
//////////////////////////////////////////////////////////////////////////////////


 module collect(
    input rst,
    input clk,
    input clk_smp,
//    input collectmark,
    input bodymark,
    input fire_once,
    input fire_achieve,
    input [7:0]now_num,
    
    input adc_ovr,//when adc_ovr = 1 , overranged or underranged
    input [13:0]adc_data,
    output shdn,//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
    output oe,// adc IC output enable pin
    output adc_clk_ttl,//adc clk
    output adc_clk_oe,// adc clk enable, =1 -> eanble
    output [4:0]gain,
    output reg we_un,
    output [13:0] wadd_un,//就和采集的点数对应起来，
    output [15:0] data_un,
    output [13:0]collect_num,
    output collect_once,     //采集完成后才进行计算
    output collect_achieve,
    output test,
    output test2
    );

reg [1:0] state_s;
parameter IDLE_S = 2'b01;
parameter ACQ = 2'b10;

reg [2:0]state_d;
parameter IDLE_D = 3'b001;
parameter WAIT_D = 3'b010;
parameter START = 3'b100;

parameter delay_time = 8'd50;//delay time us //124
parameter acq_num = 13'd512;//colect number 一次回波ADC采集的点数//2440

/**************** control wire **********************/
reg c_achieve,c_achieve_t,c_achieve_stop;
reg c_once,c_once_t,c_once_stop;
reg c_achieve1 , c_achieve2 , c_once1 , c_once2;
reg start_t;
reg num250;
/**************** conter *****************************/
reg [4:0] count_us;
reg [7:0] count_delay;
reg [13:0] acq_cnt;
reg [7:0]now_num_t;

assign gain[4:2] = 3'b000;    
assign shdn = 1'b0;
assign oe = 1'b0;
assign adc_clk_ttl = clk_smp;
assign adc_clk_oe = 1'b1;
assign collect_achieve = c_achieve1 | c_achieve2;
assign collect_once = c_once1 | c_once2;
assign wadd_un = acq_cnt;
assign data_un = { 2'b00 , adc_data };
assign collect_num = acq_num;

assign gain[0] = clk;
assign gain[1] = clk;
assign test = state_s == ACQ ? 1'b1 : 1'b0;
assign test2 = num250;


always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state_d <= IDLE_D;
        count_us <= 5'd0;
        count_delay <= 8'd0;
        start_t <= 1'b0;
    end
    else
    begin
        case(state_d)
        IDLE_D:
        begin
            start_t <= 1'b0;
            
            if(fire_once)
            begin
                state_d <= WAIT_D;
            end
        end
        WAIT_D:
        begin
             if(count_delay == delay_time)
                begin
                    state_d <= START;
                    count_delay <= 8'd0;
                    count_us <= 5'd0;
                end
                else if(count_us == 5'd19)//时钟是20M的。计数20次表示1us。
                begin
                    count_us <= 5'd0;
                    count_delay <= count_delay + 1'b1;
                end
                else
                    count_us <= count_us + 1'b1;
        end
        START:
        begin
            start_t <= 1'b1;
            if(state_s == ACQ)
                state_d <= IDLE_D;
        end
        default:
        begin
            state_d <= IDLE_D;
        end
        endcase
    end
end


always@(posedge clk_smp or posedge rst)
begin
    if(rst)
    begin
        state_s <= IDLE_S;
        acq_cnt <= 14'd0;
        c_achieve <= 1'b0;
        c_once <= 1'b0;
        we_un <= 1'b0;
    end
    else
        case(state_s)
            IDLE_S:
            begin
                acq_cnt <= 14'd0;
                c_achieve <= 1'b0;
                c_once <= 1'b0;
                we_un <= 1'b0;
                if(start_t)
                begin
                    state_s <= ACQ;
                    we_un <= 1'b1;
                end
//                else
//                    state <= IDLE;
            end
            
//            WAIT:
//            begin
//                achieve <= 1'b0;
//                count_delay <= 8'd0;
//                count_us <= 5'b0;
//                acq_cnt <= 14'd0;
//                we_un <= 1'b0;
//                c_achieve <= 1'b0;
//                c_once <= 1'b0;
//                if(fire_once == 1 && fire_achieve == 1)
//                begin
//                    state <= DELAY;
//                    achieve <= 1'b1;
//                end
//                else if(fire_once == 1)
//                    state <= DELAY;
//                else
//                begin
////                    state <= WAIT;
//                    c_achieve <= 1'b0;
//                    c_once <= 1'b0;
//                end
//            end
            
//            DELAY:
//            begin
//                if(count_delay == delay_time)
//                begin
//                    state <= ACQ;
//                    count_delay <= 8'd0;
//                    count_us <= 5'd0;
//                    we_un <= 1'b1;
//                end
//                else if(count_us == 5'd19)
//                begin
//                    count_us <= 5'd0;
//                    count_delay <= count_delay + 1'b1;
//                end
//                else
//                    count_us <= count_us + 1'b1;
//            end
            
            ACQ:
            begin
                we_un <= 1'b1;
                acq_cnt <= acq_cnt + 1'b1;
                if(acq_cnt == acq_num && num250) /// before   achieve == 1'b1
                begin
                    state_s <= IDLE_S;
                    c_achieve <= 1'b1;//一周的数据采集完成 
                    c_once <= 1'b1;
                 end 
                 else
                  if(acq_cnt == acq_num)
                 begin
                    state_s <= IDLE_S;
                    c_once <= 1'b1;//一次采集完成
                 end
//                 else
//                    state <= ACQ;
            end
            
            default:
            begin
                state_s <= IDLE_S;
            end
        endcase
end

always@(c_achieve,c_achieve_stop)
begin
    if(c_achieve)
        c_achieve_t = 1'b1;
    if(c_achieve_stop)
        c_achieve_t = 1'b0;
        
    if(c_once)
        c_once_t = 1'b1;
    if(c_once_stop)
        c_once_t = 1'b0;
end

always@(negedge clk_smp or posedge rst)
begin
    if(rst)
    begin
        now_num_t <= 8'd0;
        num250 <= 1'b0;
    end
    else
    begin
        if(now_num == 8'd250)
            num250 <= 1'b1;
        else
            num250 <= 1'b0;
        now_num_t <= now_num;
    end
end

always@ (posedge clk or posedge rst)
begin
    if(rst)
    begin
        c_achieve1 <= 1'b0;
        c_achieve2 <= 1'b0;
        c_once1 <= 1'b0;
        c_once2 <= 1'b0;
        c_achieve_stop <= 1'b0;
        c_once_stop <= 1'b0;
    end
    else
    begin
        if(c_achieve_t)
            c_achieve_stop <= 1'b1;
        else if(!c_achieve)
            c_achieve_stop <= 1'b0;
            
        if(c_once_t)
            c_once_stop <= 1'b1;
        else if(!c_once)
            c_once_stop <= 1'b0;
            
        c_achieve1 <= c_achieve_t;//延时使数据稳定或者可以增加数据的脉冲宽度
        c_achieve2 <= c_achieve1;
        c_once1 <= c_once_t;
        c_once2 <= c_once1;
    end
end

endmodule

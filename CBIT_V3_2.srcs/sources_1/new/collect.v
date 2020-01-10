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
    output [13:0] wadd_un,
    output [15:0] data_un,
    output [13:0]collect_num,
    output collect_once,
    output collect_achieve
    );

reg [1:0] state_s;
parameter IDLE_S = 2'b01;
parameter ACQ = 2'b10;

reg [2:0]state_d;
parameter IDLE_D = 3'b001;
parameter WAIT_D = 3'b010;
parameter START = 3'b100;

parameter delay_time = 8'd124;//delay time us //124
parameter acq_num = 13'd330;//colect number //2440

/**************** control wire **********************/
reg c_achieve,c_achieve_t,c_achieve_stop;
reg c_once,c_once_t,c_once_stop;
reg c_achieve1 , c_achieve2 , c_once1 , c_once2;
reg start_collect,start_t,stop_collect;
reg num250,num_t;
/**************** conter *****************************/
reg [4:0] count_us;
reg [7:0] count_delay;
reg [13:0] acq_cnt;

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

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state_d <= IDLE_D;
        count_us <= 5'd0;
        count_delay <= 8'd0;
        start_t <= 1'b0;
        num_t <= 1'b0;
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
            if(now_num == 8'd249)
                    num_t <= 1'b1;
             if(count_delay == delay_time)
                begin
                    state_d <= START;
                    count_delay <= 8'd0;
                    count_us <= 5'd0;
                end
                else if(count_us == 5'd19)
                begin
                    count_us <= 5'd0;
                    count_delay <= count_delay + 1'b1;
                end
                else
                    count_us <= count_us + 1'b1;
        end
        START:
        begin
            num_t <= 1'b0;
            start_t <= 1'b1;
            state_d <= IDLE_D;
        end
        default:
        begin
            state_d <= IDLE_D;
        end
        endcase
    end
end

always@(rst,num_t,c_achieve)
begin
    if(rst)
        num250 = 1'b0;
    if(num_t)
        num250 = 1'b1;
    if(c_achieve)
        num250 = 1'b0;
end

always@(rst,start_t,stop_collect)
begin
    if(rst)
        start_collect <= 1'b0;
    if(start_t)
        start_collect <= 1'b1;
    if(stop_collect)
        start_collect <= 1'b0;
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
        stop_collect <= 1'b0;
    end
    else
        case(state_s)
            IDLE_S:
            begin
                acq_cnt <= 14'd0;
                c_achieve <= 1'b0;
                c_once <= 1'b0;
                we_un <= 1'b0;
                stop_collect <= 1'b0;
                if(start_collect)
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
                stop_collect <= 1'b1;
                acq_cnt <= acq_cnt + 1'b1;
                if(acq_cnt == acq_num && num250) /// before   achieve == 1'b1
                begin
                    state_s <= IDLE_S;
                    c_achieve <= 1'b1;
                    c_once <= 1'b1;
                 end 
                 else if(acq_cnt == acq_num)
                 begin
                    state_s <= IDLE_S;
                    c_once <= 1'b1;
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
            
        c_achieve1 <= c_achieve_t;
        c_achieve2 <= c_achieve1;
        c_once1 <= c_once_t;
        c_once2 <= c_once1;
    end
end

endmodule

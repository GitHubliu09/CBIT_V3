`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ¼ÆËã
//////////////////////////////////////////////////////////////////////////////////


module calculate(
    input clk,
    input clk_20m,
    input rst,
    output en_read,
    output [13:0] add_r,
    input [15:0] data_r,
    input [13:0]collect_num,
//    input collectmark,
    input bodymark,
//    input stopmark,
    input fire_once,
    input collect_once,
    input collect_achieve,
    input [7:0]sweep_num,
    output reg sweep_en,
    output reg we_time,
    output reg[13:0]add_time,
    output [13:0]add_peak,
    output reg[15:0]data_time,
    output reg[15:0]data_peak,
//    output calculate_once,
    output calculate_achieve
    );
    
reg c_ach;
reg en_r;
reg cl_t_ach , cl_ach1 , cl_ach2 ,cl_ach3,cl_ach4,cl_ach5,cl_ach6;
reg c_o_t,c_o1,c_o2,c_o3,c_o4,c_o5,c_o6;
reg we_peak;

reg [13:0]acq_cnt;
reg [13:0]time_cnt;
reg [13:0]add_cnt;
reg [15:0]d_amp;
reg [15:0]a_time;
reg [15:0]a_amp;
reg [13:0]r_add_s;
reg [8:0]sweep_cnt = 9'd0;
reg [7:0]sweep_t;
reg [7:0]sweep_num1,sweep_num2;
reg sweep_change;

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

assign en_read = en_r;
assign add_r = acq_cnt;
assign add_peak = add_cnt;
assign calculate_achieve = cl_ach1 | cl_ach2 | cl_ach3 | cl_ach4 | cl_ach5 | cl_ach6;

always@(negedge clk , posedge rst)
begin
    if(rst)
    begin
        we_time <= 1'b0;
        add_time <= 14'd0;
        data_time <= 8'd0;
        data_peak <= 12'd0;
    end
    else
    begin
        we_time <= we_peak;
        add_time <= add_cnt;
        data_time <= r_add_s + delay_time;
        data_peak <= d_amp;
    end
end

always@(posedge clk , posedge rst)
begin 
    if(rst)
    begin
        sweep_num1 <= 8'd0;
        sweep_num2 <= 8'd0;
    end
    else
    begin
        sweep_num1 <= sweep_num;
        sweep_num2 <= sweep_num1;
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
        
        if(calculate_achieve)
        begin
            if(sweep_change)
            begin
                sweep_cnt <= sweep_num1;
                sweep_change <= 1'b0;
            end
            else if(sweep_cnt > sweep_t)
                sweep_cnt <= sweep_cnt + sweep_num1 - 8'd250;
            else
                sweep_cnt <= sweep_cnt + sweep_num1;
        end
        
        
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
        acq_cnt <= 14'd0;
       time_cnt <= 14'd0;
       c_ach <= 1'b0;
       en_r <= 1'b0;
       cl_t_ach <= 1'b0;
       add_cnt <= 14'd0;
       we_peak <= 1'b0;
       c_o_t <= 1'b0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
//            if(collectmark)
                state <= STARTCYCLE;
//            else
//                state <= IDLE;
        end
        
        STARTCYCLE:
        begin
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
            c_ach <= 1'b0;
            acq_cnt <= 14'd0;
            en_r <= 1'b0;
            we_peak <= 1'b0;
            cl_t_ach <= 1'b0;
            add_cnt <= 14'd0;
            if(fire_once)
            begin
                time_cnt <= 14'd0;
                state <= WAIT;
            end
//            else
//                state <= STARTCYCLE;
        end
        
        STARTONCE:
        begin
            time_cnt <= 14'd0;
            acq_cnt <= 14'd0;
            we_peak <= 1'b0;
            if(fire_once)
                state <= WAIT;
//            else
//                state <= STARTONCE;
        end
        
        WAIT:
        begin
            time_cnt <= time_cnt + 1'b1;
            if(collect_once == 1 && collect_achieve == 1)
            begin
                c_ach <= 1'b1;
                state <= CAL;
            end
            else if(collect_once == 1)
                state <= CAL;
//            else
//                state <= WAIT;
        end
        
        CAL:
        begin
            en_r <= 1'b1;
            we_peak <= 1'b0;
            time_cnt <= time_cnt + 1'b1;
            if(acq_cnt == collect_num)
            begin
                state <= WRITE;
                acq_cnt <= 14'd0;
            end
            else
                acq_cnt <= acq_cnt + 1'b1;
            if(data_r > d_amp)
            begin
                d_amp <= {2'b00,data_r};
                r_add_s <= acq_cnt;
            end
        end
        
        WRITE:
        begin
            c_o_t<= 1'b1;
            we_peak <= 1'b1;
            en_r <= 1'b0;
            state <= DONE;
        end
        
        DONE:
        begin
            c_o_t <= 1'b0;
            en_r <= 1'b0;
            we_peak <= 1'b0;
            d_amp <= 16'd0;
            r_add_s <= 14'd0;
            //if(stopmark)
            //    state <= IDLE;
            //else
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
    
endmodule

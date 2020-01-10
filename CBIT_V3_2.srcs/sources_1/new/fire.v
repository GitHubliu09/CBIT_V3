`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////

module fire(
    input rst,
    input clk_20m,
    input bodymark,
    input oncemark,
    output oe,
    output fire_a,
    output fire_b,
    output fire_c,
    output fire_d,
    output fire_once,
    output fire_achieve,
    output [2:0]pulse_num,
    output error_fire
    );
    
    
    reg fire_t_a = 1'b0;
    reg fire_t_b = 1'b0;
    reg fire_t_c = 1'b0;
    reg fire_t_d = 1'b0; 
    reg fire_t_once = 1'b0; 
    reg fire_t_ach = 1'b0;
    reg    fire_t_once1 ,fire_t_once2,fire_t_ach1 ,fire_t_ach2 ;
    
    reg[4:0] state = 5'b00001 , next_state = 5'b00001;
    parameter IDLE = 5'b00001;
    parameter WAITB = 5'b00010;
    parameter WAITO = 5'b00100;
    parameter FIRE = 5'b01000;
    parameter FIREDONE = 5'b10000;
    
    reg[7:0] fire_num = 8'd0 ;//计数发射个数
    reg [7:0] pulse_cnt = 8'd0;  //用于计数单个发射周期内的变量
    parameter pulse_cnt_num = 8'd2;//=5 -> 发射4次
    reg [7:0] duration_cnt = 8'd0;
    reg start_fire = 1'b0 , start_fire_t = 1'b0;//开始发射
    
    assign oe = 1'b1;
    assign fire_a = fire_t_a;
    assign fire_b = ~fire_t_b;
    assign fire_c = fire_t_d;
    assign fire_d = fire_t_d;
    assign fire_once = fire_t_once1 | fire_t_once2;
    assign fire_achieve = fire_t_ach1 | fire_t_ach2;
    assign pulse_num = pulse_cnt_num;
    
    assign error_fire = fire_t_ach;
    
    
    always@(negedge clk_20m or posedge rst)
    begin
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always@( state ,bodymark,oncemark , fire_t_once)
    begin
        next_state = state;
//        if(bodymark)      //之后需要
//            fire_num = 8'd0;
        case(state)
            IDLE:
            begin
                next_state = WAITB;
                start_fire = 1'b0;
                fire_num = 8'd0;
                fire_t_ach = 1'b0;
            end
            WAITB:
            begin
                if(bodymark)
                    next_state = WAITO;
            end
            WAITO:
            begin
                if(oncemark)
                begin
                    next_state = FIRE;
                    fire_num = fire_num + 1'b1;
                end
            end
            FIRE:
            begin
                if(fire_t_once)
                begin
                    next_state = FIREDONE;
                    if(fire_num == 8'd250)
                        fire_t_ach = 1'b1;
                end
                start_fire = 1'b1;
            end
            FIREDONE:
            begin
                if(fire_num == 8'd250)//发射250次后等待bodymark
                begin
                    next_state = IDLE;
                end
                else next_state = WAITO;
                start_fire = 1'b0;
            end
            default:
            begin
                next_state = IDLE;
            end
        endcase
    end
    
    always@(posedge clk_20m or posedge rst)
    begin
        if(rst)
        begin
//            fire_num <= 8'd0;
            pulse_cnt <= 8'd0;
            duration_cnt <= 8'd0;
            fire_t_a <= 1'b0;
            fire_t_b <= 1'b0;
            fire_t_c <= 1'b0;
            fire_t_d <= 1'b0;
//            start_fire_t <= 1'b0;
            fire_t_once <= 1'b0;
        end
        else
        begin
            if(start_fire)
//                start_fire_t <= 1'b1;
//            else if(start_fire_t)
            begin
            if(pulse_cnt < pulse_cnt_num)
            begin
                 if(duration_cnt == 8'd79)
                     begin
                        pulse_cnt <= pulse_cnt + 1'b1;
                        duration_cnt <= 8'd0;
                     end
                 else
                    begin
                        duration_cnt <= duration_cnt + 1'b1;
                        fire_t_a <= (duration_cnt <= 8'd39)?1'b1:1'b0;
                        fire_t_b <= ((duration_cnt >= 8'd40)&&(duration_cnt <=8'd79) )?1'b1:1'b0;
                    end
             end
             else
             begin
                    if(pulse_cnt == pulse_cnt_num)
                    begin
                            fire_t_a <= 1'b0;
                            fire_t_b <= 1'b0;
                            if(duration_cnt == 8'd79)
                            begin
//                                  fire_num <= fire_num + 1;
                                  fire_t_once <= 1'b1;
//                                  if(fire_num == 8'd249)
//                                    fire_t_ach <= 1'b1;
//                                    start_fire_t <= 1'b0;
                                  pulse_cnt <= 4'd0;
                           end
                           else
                           begin
                                  duration_cnt <= duration_cnt + 1'b1;
                                  fire_t_d <= (duration_cnt <= 8'd39)?1'b1:1'b0;
                           end
                    end
                    else
                    begin
                            if(duration_cnt == 8'd99)
                            begin
                                    pulse_cnt <= pulse_cnt + 1'b1;
                                    duration_cnt <= 8'd0;
                             end
                             else
                             begin
                                    duration_cnt <= duration_cnt + 1'b1;
                                    fire_t_a <= (duration_cnt <= 8'd39)?1'b1:1'b0;
                                    fire_t_b <= ((duration_cnt >= 8'd40)&&(duration_cnt <=8'd79) )?1'b1:1'b0;
                             end
                    end
                end
            end
            else
            begin
//                fire_num <= 8'd0;
                fire_t_once <= 1'b0;
            end
        end
    end

always @(posedge clk_20m or posedge rst)
begin
    if(rst)
    begin
    fire_t_once1 <= 1'b0;
    fire_t_once2 <= 1'b0;
    fire_t_ach1 <= 1'b0;
    fire_t_ach2 <= 1'b0;
    end
    else
    begin
        fire_t_once1 <= fire_t_once;
        fire_t_once2 <= fire_t_once1;
        fire_t_ach1 <= fire_t_ach;
        fire_t_ach2 <= fire_t_ach1;
    end
end
    
endmodule

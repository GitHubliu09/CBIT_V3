`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//     空闲->等待bodymark->等待齿牙（oncemark）->fire(根据高压脉冲数判断是否完成一次，根据发射次数是否完成了一周)->
//     完成一周的发射后输出发射完成信号，并进入空闲状态等待下一个bodymark信号
// 
//////////////////////////////////////////////////////////////////////////////////

module fire(
    input rst,
    input clk_20m,
    input bodymark,
    input oncemark,
    input collect_achieve,
    input [7:0]now_num,
    output oe_15,
    output oe_20,
    output oe_nj,
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
    reg oe_15_t,oe_nj_t;
    reg nj_done;
    
    reg[5:0] state = 6'b00001 , next_state = 6'b00001;
    parameter IDLE = 6'b000001;
    parameter WAITB = 6'b000010;
    parameter WAITO = 6'b000100;
    parameter FIRE = 6'b001000;
    parameter FIREDONE = 6'b010000;
    parameter WAITNJ = 6'b100000;
    
  reg[7:0] fire_num = 8'd0 ;//计数发射个数
    reg [7:0] pulse_cnt = 8'd0;  //用于计数单个发射周期内的变量
    parameter pulse_cnt_num = 8'd2;//=5 -> 发射4次
    reg [7:0] duration_cnt = 8'd0;
    reg start_fire = 1'b0 , start_fire_t = 1'b0;//开始发射
    
    assign oe_15 = 1'b0;
    assign oe_20 = 1'b0;
    assign oe_nj = 1'b1;
    assign fire_a = fire_t_a;
    assign fire_b = ~fire_t_b;
    assign fire_c = fire_t_d;
    assign fire_d = fire_t_d;
    assign fire_once = fire_t_once1 | fire_t_once2;      //增加脉冲宽度
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
    
    always@( state ,bodymark,oncemark , fire_t_once ,collect_achieve)
    begin
        next_state = state;
        
//        if(bodymark)      //涔嬪悗闇?瑕?
//            fire_num = 8'd0;
        case(state)
            IDLE:
            begin
                next_state = WAITB;
                start_fire = 1'b0;
                fire_num = 8'd0;
                fire_t_ach = 1'b0;
                nj_done = 1'b0;
                oe_15_t = 1'b1;
                oe_nj_t = 1'b0;
            end
            WAITB:
            begin
                if(bodymark)
                    next_state = WAITO;
            end
            WAITO:                              //绛夊緟榻跨墮淇″彿
            begin
                nj_done <= 1'b0;
                if(oncemark)
                begin
                    oe_15_t = 1'b1;
                    oe_nj_t = 1'b0;
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
                    begin
                        fire_t_ach = 1'b1;
                    end
                end
                start_fire = 1'b1;
            end
            FIREDONE:
            begin
                if(now_num == 8'd250)//鍙戝皠250娆″悗绛夊緟bodymark
                begin
                        fire_num = 8'd0;
                        next_state = IDLE;//无测试泥浆
//                        next_state = WAITNJ;//代表有测试泥浆
                end
                else next_state = WAITO;//绛夊緟榻跨墮淇″彿杩涜涓嬩竴娆″彂灏?
                start_fire = 1'b0;
            end
            WAITNJ:
            begin
                nj_done = 1'b1;
                start_fire = 1'b0;
                if(collect_achieve)
                begin
                    oe_15_t = 1'b0;
                    oe_nj_t = 1'b1;
                    next_state = FIRE;
                    fire_num = 8'd0;
                    fire_t_ach = 1'b0;
                end
                else if(oncemark)
                begin
                    oe_15_t = 1'b1;
                    oe_nj_t = 1'b0;
                    next_state = FIRE;
                    fire_num = fire_num + 1'b1;
                end
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
                 if(duration_cnt == 8'd79)//持续的时间，输入的时钟是20m计数80次对应发射的声波是250khz
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
                    if(pulse_cnt == pulse_cnt_num)   //发射次数到了
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
                    else  //杩欎釜else杩涗笉鏉?
                    begin
                            if(duration_cnt == 8'd99)
                            begin
                                    pulse_cnt <= pulse_cnt + 1'b1;
                                    duration_cnt <= 8'd0;
                             end
                             else
                             begin
                                    duration_cnt <= duration_cnt + 1'b1;
                                    fire_t_a <= (duration_cnt <= 8'd39)?1'b1:1'b0;//浜х敓婵?鍙戞崲鑳藉櫒鐨勬柟娉?
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//     空闲->等待bodymark->等待齿牙（oncemark）->fire(根据高压脉冲数判断是否完成一次，根据发射次数是否完成了一周)->
//     完成一周的发射后输出发射完成信号，并进入空闲状态等待下一个bodymark信号
// 
//////////////////////////////////////////////////////////////////////////////////

module fire(
    input rst,
    input clk_20m,
    input bodymark,
    input oncemark,
    input collect_achieve,
    input [7:0]now_num,
    output oe_15,
    output oe_20,
    output oe_nj,
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
    reg oe_15_t,oe_nj_t;
    reg nj_done;
    
    reg[5:0] state = 6'b00001 , next_state = 6'b00001;
    parameter IDLE = 6'b000001;
    parameter WAITB = 6'b000010;
    parameter WAITO = 6'b000100;
    parameter FIRE = 6'b001000;
    parameter FIREDONE = 6'b010000;
    parameter WAITNJ = 6'b100000;
    
  reg[7:0] fire_num = 8'd0 ;//计数发射个数
    reg [7:0] pulse_cnt = 8'd0;  //用于计数单个发射周期内的变量
    parameter pulse_cnt_num = 8'd2;//=5 -> 发射4次
    reg [7:0] duration_cnt = 8'd0;
    reg start_fire = 1'b0 , start_fire_t = 1'b0;//开始发射
    
    assign oe_15 = 1'b0;
    assign oe_20 = 1'b0;
    assign oe_nj = 1'b1;
    assign fire_a = fire_t_a;
    assign fire_b = ~fire_t_b;
    assign fire_c = fire_t_d;
    assign fire_d = fire_t_d;
    assign fire_once = fire_t_once1 | fire_t_once2;      //增加脉冲宽度
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
    
    always@( state ,bodymark,oncemark , fire_t_once ,collect_achieve)
    begin
        next_state = state;
        
//        if(bodymark)      //涔嬪悗闇?瑕?
//            fire_num = 8'd0;
        case(state)
            IDLE:
            begin
                next_state = WAITB;
                start_fire = 1'b0;
                fire_num = 8'd0;
                fire_t_ach = 1'b0;
                nj_done = 1'b0;
                oe_15_t = 1'b1;
                oe_nj_t = 1'b0;
            end
            WAITB:
            begin
                if(bodymark)
                    next_state = WAITO;
            end
            WAITO:                              //绛夊緟榻跨墮淇″彿
            begin
                nj_done <= 1'b0;
                if(oncemark)
                begin
                    oe_15_t = 1'b1;
                    oe_nj_t = 1'b0;
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
                    begin
                        fire_t_ach = 1'b1;
                    end
                end
                start_fire = 1'b1;
            end
            FIREDONE:
            begin
                if(now_num == 8'd250)//鍙戝皠250娆″悗绛夊緟bodymark
                begin
                        fire_num = 8'd0;
                        next_state = IDLE;//无测试泥浆
//                        next_state = WAITNJ;//代表有测试泥浆
                end
                else next_state = WAITO;//绛夊緟榻跨墮淇″彿杩涜涓嬩竴娆″彂灏?
                start_fire = 1'b0;
            end
            WAITNJ:
            begin
                nj_done = 1'b1;
                start_fire = 1'b0;
                if(collect_achieve)
                begin
                    oe_15_t = 1'b0;
                    oe_nj_t = 1'b1;
                    next_state = FIRE;
                    fire_num = 8'd0;
                    fire_t_ach = 1'b0;
                end
                else if(oncemark)
                begin
                    oe_15_t = 1'b1;
                    oe_nj_t = 1'b0;
                    next_state = FIRE;
                    fire_num = fire_num + 1'b1;
                end
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
                 if(duration_cnt == 8'd79)//持续的时间，输入的时钟是20m计数80次对应发射的声波是250khz
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
                    if(pulse_cnt == pulse_cnt_num)   //发射次数到了
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
                    else  //杩欎釜else杩涗笉鏉?
                    begin
                            if(duration_cnt == 8'd99)
                            begin
                                    pulse_cnt <= pulse_cnt + 1'b1;
                                    duration_cnt <= 8'd0;
                             end
                             else
                             begin
                                    duration_cnt <= duration_cnt + 1'b1;
                                    fire_t_a <= (duration_cnt <= 8'd39)?1'b1:1'b0;//浜х敓婵?鍙戞崲鑳藉櫒鐨勬柟娉?
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

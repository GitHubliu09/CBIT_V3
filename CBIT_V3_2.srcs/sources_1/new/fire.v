`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////

module fire(
    input rst,
    input clk_20m,
    input collectmark,
    input bodymark,
    input oncemark,
    input stopmark,
    output oe,
    output fire_a,
    output fire_b,
    output fire_c,
    output fire_d,
    output fire_once,
    output fire_achieve,
    output [2:0]pulse_num,
    output error_fire,
    output state
    );
    
    reg error_fire = 1'b0;
    
    reg fire_t_a = 1'b0;
    reg fire_t_b = 1'b0;
    reg fire_t_c = 1'b0;
    reg fire_t_d = 1'b0; 
    reg fire_t_once = 1'b0; 
    reg fire_t_ach = 1'b0;
    reg    fire_t_once1 ,fire_t_once2,fire_t_ach1 ,fire_t_ach2 ;
    
    reg[1:0] state = 2'b00;
    parameter IDLE = 2'b00;
    parameter WAITB = 2'b01;
    parameter WAITO = 2'b11;
    parameter FIRE = 2'b10;
    
    reg[7:0] fire_num = 8'd0 ;//计数发射个数
    reg [7:0] pulse_cnt = 8'd0;  //用于计数单个发射周期内的变量
    parameter pulse_cnt_num = 8'd5;//=5 -> 发射4次
    reg [7:0] duration_cnt = 8'd0;
    
    assign oe = 1'b1;
    assign fire_a = fire_t_a;
    assign fire_b = ~fire_t_b;
    assign fire_c = fire_t_d;
    assign fire_d = fire_t_d;
    assign fire_once = fire_t_once1 | fire_t_once2;
    assign fire_achieve = fire_t_ach1 | fire_t_ach2;
    assign pulse_num = pulse_cnt_num;
    
    always@(posedge clk_20m or posedge rst)
    begin
        if(rst)
        begin
            fire_num <= 8'd0;
            pulse_cnt <= 8'd0;
            duration_cnt <= 8'd0;
            fire_t_a <= 1'b0;
            fire_t_b <= 1'b0;
            fire_t_c <= 1'b0;
            fire_t_d <= 1'b0;
            state <= IDLE;
            error_fire <= error_fire + 1'b1;
        end
        else
        case(state)
        IDLE:
        begin
            fire_t_once <= 1'b0;
            fire_t_ach <= 1'b0;
            if(collectmark)
                state <= WAITB;
        end
        
        WAITB:
        begin
            if(bodymark)
                state <= WAITO;
            else
            begin
                fire_t_once <= 1'b0;
                fire_t_ach <= 1'b0;
            end
        end
        
        WAITO:
        begin
            if(oncemark)
            begin
                state <= FIRE;
            end
            else if(fire_num == 8'd250 && stopmark == 1'b1)//fire_num == 5 -> 每发射5次，回到等待bodymark   ,需要同时更改下面
                begin
                    fire_num <= 8'd0;
                    state <= IDLE;
                end
            else if(fire_num == 8'd250)
                begin
                    fire_num <= 8'd0;
                    state<= WAITB;
                end
            else
            begin
                fire_t_once <= 1'b0;
                fire_t_ach <= 1'b0;
            end
                
        end
        
        FIRE:
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
                                  state <= WAITO;
                                  fire_num <= fire_num + 1;
                                  fire_t_once <= 1'b1;
                                  if(fire_num == 8'd249)
                                    fire_t_ach <= 1'b1;
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
     
        default:
        begin
            //error_fire <= 1'b1;
            if(stopmark)
            begin
               // state <= IDLE;
            end
            else
                state <= WAITB;
            
        end
        endcase
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

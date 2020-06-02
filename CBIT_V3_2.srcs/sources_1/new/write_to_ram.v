`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  wirte_to_ram.v
//  wirte data to ram for edib send
//////////////////////////////////////////////////////////////////////////////////


module write_to_ram(
    input clk,
    input clk_20m,
    input rst,
    input oncemark,
    input bodymark,
//    input stopmark,
    input we_time,           //（根据前面模块调用时的信息）写使能
    input we_peak,           //写使能，与上一个输入相同
    input [13:0]add_time,    //写的地址
    input [13:0]add_peak,    //写的地址，与上一个输入相同
    input [7:0]data_time,   //到时
    input [11:0]data_peak,   //峰值
    input calculate_achieve,
    input [7:0]now_num,
    input sweep_en,
    input sweep_add,
    input [15:0]sweep_data,//现在是在untreated_data_ram里读出来的
    input change_message,
    input [15:0]message1,
    input [15:0]message2,
    input [15:0]message3,
    input [15:0]message4,
    input [15:0]message5,
    input [15:0]message6,
    input [15:0]message7,
    input [15:0]message8,
    input [15:0]message9,
    input [15:0]message10,
    input [15:0]message11,
    input [7:0]extract_num,
    
    output write_ram_done,
    output reg stop_message,
    output write_en,
    output [13:0]write_add,
    output [15:0]write_data,
    output test
    );

reg write_en;
reg [13:0]write_add_t;
reg [15:0]write_data_t;
/*************** contorl reg *****************************/
reg change_msg,w_time,w_peak,w_sweep,sweep_en_t;
reg [1:0]add_t;
reg calculate_achieve_t,calculate_achieve_s;
/************** data reg **********************************/
reg [15:0]time_reg , peak_reg;
reg [7:0]peak_t_reg;
reg [7:0]time_save;
reg [11:0]peak_save;
/************** counter reg **************************/
reg [3:0]msg_cnt;
reg [8:0]sweep_cnt;
reg [8:0]time_cnt;
reg [8:0]peak_cnt;
reg [3:0]write_add_cnt;
reg [7:0]extract_cnt;
reg [8:0]sweep_i;
/************* word[0..10] data ************************/
reg [15:0]messge_1 , messge_2 ,messge_3 ,messge_4 ,messge_5 ,messge_6 ,messge_7 ,messge_8 ,messge_9 ,messge_10 ,messge_11 ;
/*************** test wire ****************************************/
reg [15:0]sweep_data_test;
wire test;
assign test = ( sweep_data == 16'd0) ? 1'b1 : 1'b0;

reg [7:0]state,next_state;
parameter IDLE = 8'b0000_0001;
parameter WAIT = 8'b0000_0010;
parameter MSG = 8'b0000_0100;
parameter MSG_DONE = 8'b0000_1000;
parameter WAIT_TP = 8'b0001_0000;
parameter TIME = 8'b0010_0000;
parameter PEAK = 8'b0100_0000;
parameter DONE = 8'b1000_0000;


assign write_add = write_add_t ;//实际用时候，上传参数发现整体向前移一位，所以每一个地址 +1
assign write_data = write_data_t;
assign write_ram_done = calculate_achieve_t;//下降沿时，代表写ram完成

always@(negedge clk or posedge rst)
begin
    if(rst)
    begin
        sweep_data_test <= 16'd0;
    end
    else
    begin
        if(sweep_data == 16'd0)
            sweep_data_test <= 16'd1;
         else
            sweep_data_test <= sweep_data;
    end
end


always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        messge_1 <= 16'd0;
        messge_2 <= 16'd0;
        messge_3 <= 16'd0;
        messge_4 <= 16'd0;
        messge_5 <= 16'd0;
        messge_6 <= 16'd0;
        messge_7 <= 16'd0;
        messge_8 <= 16'd0;
        messge_9 <= 16'd0;
        messge_10 <= 16'd0;
        messge_11 <= 16'd0;
    end
    else
    begin
            messge_1 <= message1;
            messge_2 <= message2;
            messge_3 <= message3;
            messge_4 <= message4;
            messge_5 <= message5;
            messge_6 <= message6;
            messge_7 <= message7;
            messge_8 <= message8;
            messge_9 <= message9;
            messge_10 <= message10;
            messge_11 <= message11;
    end
end

//always@(posedge clk or posedge rst)
//begin
//    if(rst)
//    begin
//        state <= IDLE;
//    end
//    else
//    begin
//        state <= next_state;
//    end
//end

//always@(state,bodymark)
//begin
//    next_state = state;
//    case(state)
//    IDLE:
//    begin
//        next_state = WAIT;
//    end
//    WAIT:
//    begin
//        sweep_cnt <= 9'd11;
//        time_cnt <= 9'd139;
//        peak_cnt <= 9'd264;
//        msg_cnt <= 4'd0;
//        calculate_achieve_s <= 1'b0;
//        if(bodymark)
//            next_state <= MSG;
//    end
//    MSG:
//    begin
    
//    end
    
//    endcase
//end

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        msg_cnt <= 4'd0;
        sweep_cnt <= 9'd11;
        time_cnt <= 9'd139;
        peak_cnt <= 9'd264;
        time_reg <= 16'd0;
        peak_reg <= 16'd0;
        peak_t_reg <= 8'd0;
        write_add_cnt <= 4'd0;
        write_add_t <= 14'd0;
        write_data_t <= 16'd0;
        sweep_en_t <= 1'b0;
        w_sweep <= 1'b0;
        w_time <= 1'b0;
        w_peak <= 1'b0;
        calculate_achieve_s <= 1'b0;
        time_save <= 8'd0;
        peak_save <= 12'd0;

    end
    else
    begin
        case(state)
        IDLE:
        begin
            if(bodymark)
                state <= WAIT;
//            else
//                state <= IDLE;
        end
        
        WAIT:
        begin
            sweep_cnt <= 9'd11;
            time_cnt <= 9'd139;
            peak_cnt <= 9'd264;
//            if(change_message)    //if message changed , write message agine
//            begin
                msg_cnt <= 4'd0;
//                stop_message <= 1'b1;
//            end
//            else
//            begin
//                stop_message <= 1'b0;
//            end
            calculate_achieve_s <= 1'b0;
//            if(oncemark)
                state <= MSG;//写message1-11只在每一周期开始时写的，以bodymak信号或者上周结束信号作为开始的同步信号
//            else if(stopmark)
//                state <= IDLE;
//            else
//                state <= WAIT;
        end
        
        MSG://write message into ram(11 word)
        begin
            if(msg_cnt != 4'd11)
            begin
                write_en <= 1'b1;
                case(msg_cnt)
                4'd0 : 
                    begin
                    write_data_t <= messge_1;//test messge_1
                    write_add_t <= 14'd0;//对应的地址
                    end
                4'd1 : 
                    begin
                    write_data_t <= messge_2;//test messge_2
                    write_add_t <= 14'd1;
                    end
                4'd2 : 
                    begin
                    write_data_t <= messge_3;//test  messge_3
                    write_add_t <= 14'd2;
                    end
                4'd3 : 
                    begin
                    write_data_t <= messge_4;//test  messge_4
                    write_add_t <= 14'd3;
                    end
                4'd4 : 
                    begin
                    write_data_t <= messge_5;//test messge_5
                    write_add_t <= 14'd4;
                    end
                4'd5 : 
                    begin
                    write_data_t <= messge_6;//test messge_6
                    write_add_t <= 14'd5;
                    end
                4'd6 : 
                    begin
                    write_data_t <= messge_7;//test messge_7
                    write_add_t <= 14'd6;
                    end
                4'd7 : 
                    begin
                    write_data_t <= messge_8;//test messge_8 
                    write_add_t <= 14'd7;
                    end
                4'd8 : 
                    begin
                    write_data_t <= messge_9;//test messge_9
                    write_add_t <= 14'd8;
                    end
                4'd9 : 
                    begin
                    write_data_t <= messge_10;//test messge_10
                    write_add_t <= 14'd9;
                    end
                4'd10 : 
                    begin
                    write_data_t <= messge_11;//test messge_11
                    write_add_t <= 14'd10;
                    end
//                 4'd11:
//                    begin
//                    write_data_t <= 16'hf1f1;
//                    write_add_t <= 14'd451;
//                    end
//                 4'd12:
//                    begin
//                    write_data_t <= 16'hee22;
//                    write_add_t <= 14'd452;
//                    end
                endcase
                state <= MSG_DONE;
            end
            else
            begin
                write_en <= 1'b0;
                state <= WAIT_TP;
            end
        end
        
        MSG_DONE:
        begin
            msg_cnt <= msg_cnt + 1'b1;
            write_en <= 1'b0;
            state <= MSG;
        end
        
        WAIT_TP:
        begin
            write_add_cnt <= 4'd0;
            if(we_time)
            begin
                time_save <= data_time;
                peak_save <= data_peak;
                add_t <= add_time[1:0];//add_time输入的是地址，地址的末位是0 1 交替的 这样来判断拼接
                state <= TIME;
            end
            else
                state <= WAIT_TP;
            
            if(sweep_en)
                sweep_en_t <= 1'b1;
            else if(write_add_t == 9'd138)//sweep_cnt//128个波形数据写完了，把使能关掉   地址为11到138  
                sweep_en_t <= 1'b0;
            
            if(sweep_en_t)
                w_sweep <= 1'b1;
            else 
            begin
                sweep_cnt <= 9'd11;//存在ram里面的地址，前面的message已经存了10个地址了，后面的就要从11开始加
                w_sweep <= 1'b0;
            end
            
            if(w_sweep)//write sweep int ram
            begin
                write_en <= 1'b1;
                
                if(extract_cnt == extract_num)
                begin
                    sweep_i <= sweep_i + 1'b1;
                    if(sweep_i[0] == 1'b1)//拼接时候用的，0 1 2 3  4 排列起来最后一位都是 0 1 交替的
                    begin
                        write_data_t[7:0] <=  sweep_data[13:6] ; //  sweep_data[13:6]   test // 只上传了adc的高8位数据
                        sweep_cnt <= sweep_cnt + 1'b1;
                    end
                    else
                    begin
                        write_data_t[15:8] <= sweep_data[13:6] ;  // sweep_data[13:6]  test
                        write_add_t <= sweep_cnt;
                    end
                    extract_cnt <= 8'd0;
                end
                else
                begin
                    extract_cnt <= extract_cnt + 1'b1;
                end
            end
            else
            begin
                extract_cnt <= 8'd0;
                sweep_i <= 9'd0;
                write_en <= 1'b0;
            end
        end
        
        TIME://数据拼接，8位转16bit
        begin
            write_en <= 1'b0;
            if(add_t[0] == 1'b0)
                time_reg[15:8] <= time_save;
            else
            begin
                time_reg[7:0] <= time_save;
                w_time <= 1'b1;
            end
           state <= PEAK;
        end
        
        PEAK://数据拼接，12bit接16bit
        begin
            state <= DONE;
            if(add_t[1:0] == 2'b00)
            begin
                peak_reg[15:4] <= peak_save;//12bits的幅度数据
            end
            else if(add_t[1:0] == 2'b01)
            begin
                peak_reg[3:0] <= peak_save[11:8];
                peak_t_reg <= peak_save[7:0];//带t临时变量，存储这次周期peak_save中没有存储进peak_reg中的数据
                w_peak <= 1'b1;
            end
            else if(add_t[1:0] == 2'b10)
            begin
                peak_reg[15:8] <= peak_t_reg;
                peak_reg[7:0] <= peak_save[11:4];
                peak_t_reg[3:0] <= peak_save[3:0];
                w_peak <= 1'b1;
            end
            else if(add_t[1:0] == 2'b11)
            begin
                peak_reg[15:12] <= peak_t_reg[3:0];
                peak_reg[11:0] <= peak_save;
                w_peak <= 1'b1;
            end
        end
        
        DONE://write time and peak into ram (125 word time , 188 word peak)
        begin
            write_add_cnt <= write_add_cnt + 1'b1;
            case(write_add_cnt)
            4'd1 : if(w_time)
                    begin
                    write_add_t <= time_cnt;
                    write_data_t <= time_reg; //  time_reg  test
                    write_en <= 1'b1;
                    time_cnt <= time_cnt + 1'b1;
                    end
                    
            4'd3 : if( w_peak)
                    begin
                    write_add_t <= peak_cnt;
                    write_data_t <= 16'd0;// peak_reg  test
                    write_en <= 1'b1;
                    peak_cnt <= peak_cnt + 1'b1;
                    end
            
            4'd5 : if(calculate_achieve_t)
                    begin
                    write_add_t <= peak_cnt;
                    write_data_t <=  {8'd0 , 8'b0000_0000};//  {peak_t_reg , 8'b0000_0000}  test
                    write_en <= 1'b1;
                    end
            
            4'd7 : begin
                    write_en <= 1'b0;
                    w_time <= 1'b0;
                    w_peak <= 1'b0;
                    if(calculate_achieve_t && write_add_t > 13'd160)
                    begin
                        state <= WAIT;
                        calculate_achieve_s <= 1'b1;
                    end
                    else
                        state <= WAIT_TP;
                    end
                
           endcase     
            
        end
        
        default:
        begin
            state <= IDLE;
        end
        endcase
    end
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        calculate_achieve_t <= 1'b0;
    else 
    begin
    if(calculate_achieve)
        calculate_achieve_t <= 1'b1;//把这个计算完成的脉冲延长（产生和使用不在一个时间）使用完成之后在清零
    if(calculate_achieve_s)
        calculate_achieve_t <= 1'b0;
    end
end

endmodule

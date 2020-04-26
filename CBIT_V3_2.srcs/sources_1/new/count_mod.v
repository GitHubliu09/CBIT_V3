`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 计数此刻位于bodymark之后第几个齿牙信号
// 计算齿牙信号的位置，在1-250中的哪一个位置
//////////////////////////////////////////////////////////////////////////////////


module count_mod(
    input clk,
    input rst,
    input bodymark,
    input oncemark,
    output [7:0] num,
    output reg[7:0]num_d,
    output test
    );

reg [7:0]num_t;
reg [15:0]cnt;

reg [3:0]state;
parameter IDLE = 4'b0001;
parameter WAITO = 4'b0010;
parameter ADD = 4'b0100;
parameter WAIT = 4'b1000;

assign num = num_t;
assign test = (num == 8'd250) ? 1'b1 : 1'b0;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        num_d <= 8'd0;
    end
    else
    begin
        if(num_t != 8'd0)
            num_d <= num_t;
        else
            num_d <= num_d;
    end
end


always@( posedge clk or posedge rst)
begin
    if(rst)
    begin
        num_t <= 8'd0;
    end
    else
        begin
            if(bodymark)//每一周的起始位置
            num_t <= 8'd0;
        case(state)
        IDLE:
        begin
            num_t <= 8'd0;
            state <= WAITO;
        end
        WAITO:
        begin
            if(oncemark)//每一次齿牙信号
            begin
                state <= ADD;
            end
        end
        ADD:
        begin
            num_t <= num_t + 1'b1;
            state <= WAIT;
        end
        WAIT:
        begin
            if(cnt == 16'd2)
                state <= WAITO;
        end
        default:
            state <= IDLE;
        endcase
    end

end

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cnt <= 16'd3;
/*因为pic单片机发送过来的一次齿牙信号持续的时间可能比fpga的时钟周期更久，为了不重复读取增加了延时部分，延时的时间是1000，初始化
为3，判断计数到2，是为了在修改程序的时候只用改一次1000.*/
    end
    else if(state == WAIT)
    begin
        if(cnt == 16'd1000)
            cnt <= 16'd0;
        else
            cnt <= cnt + 1'b1;
    end
    else
        cnt <= 16'd3;
end



endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 计数此刻位于bodymark之后第几个齿牙信号
// 计算齿牙信号的位置，在1-250中的哪一个位置
//////////////////////////////////////////////////////////////////////////////////


module count_mod(
    input clk,
    input rst,
    input bodymark,
    input oncemark,
    output [7:0] num,
    output reg[7:0]num_d,
    output test
    );

reg [7:0]num_t;
reg [15:0]cnt;

reg [3:0]state;
parameter IDLE = 4'b0001;
parameter WAITO = 4'b0010;
parameter ADD = 4'b0100;
parameter WAIT = 4'b1000;

assign num = num_t;
assign test = (num == 8'd250) ? 1'b1 : 1'b0;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        num_d <= 8'd0;
    end
    else
    begin
        if(num_t != 8'd0)
            num_d <= num_t;
        else
            num_d <= num_d;
    end
end


always@( posedge clk or posedge rst)
begin
    if(rst)
    begin
        num_t <= 8'd0;
    end
    else
        begin
            if(bodymark)//每一周的起始位置
            num_t <= 8'd0;
        case(state)
        IDLE:
        begin
            num_t <= 8'd0;
            state <= WAITO;
        end
        WAITO:
        begin
            if(oncemark)//每一次齿牙信号
            begin
                state <= ADD;
            end
        end
        ADD:
        begin
            num_t <= num_t + 1'b1;
            state <= WAIT;
        end
        WAIT:
        begin
            if(cnt == 16'd2)
                state <= WAITO;
        end
        default:
            state <= IDLE;
        endcase
    end

end

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cnt <= 16'd3;
/*因为pic单片机发送过来的一次齿牙信号持续的时间可能比fpga的时钟周期更久，为了不重复读取增加了延时部分，延时的时间是1000，初始化
为3，判断计数到2，是为了在修改程序的时候只用改一次1000.*/
    end
    else if(state == WAIT)
    begin
        if(cnt == 16'd1000)
            cnt <= 16'd0;
        else
            cnt <= cnt + 1'b1;
    end
    else
        cnt <= 16'd3;
end



endmodule

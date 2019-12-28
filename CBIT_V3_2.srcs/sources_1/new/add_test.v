`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/28 10:29:46
// Design Name: 
// Module Name: add_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module add_test(
    input rst,
    input clk_1m,
    
    output [7:0]data,
    output [14:0]add
    );

reg [3:0]state;
parameter IDLE = 4'b0001;
parameter BODY = 4'b0010;
parameter ONCE = 4'b0100;
parameter WAIT = 4'b1000;

reg [7:0]data_t = 8'b0;
reg [14:0]add_t = 15'd0;

reg [5:0]cnt_t = 6'd0;
reg [11:0]cnt = 12'd0;
reg [7:0]num = 8'd0;

assign data = data_t;
assign add = add_t;

always@(posedge clk_1m or posedge rst)
begin
    if(rst)
    begin
        data_t <= 8'd0;
        add_t <= 15'd0;
        cnt <= 12'd0;
        num <= 8'd0;
        state <= IDLE;
    end
    else
    begin
    case(state)
        IDLE:
        begin
            add_t <= 15'd0;
            state <= BODY;
        end
        BODY:
        begin
            add_t <= 15'h0801;
            num <= 8'd0;
            state <= ONCE;
        end
        ONCE:
        begin
            add_t <= 15'h0802;
            num <= num + 1'b1;
            state <= WAIT;
        end
        WAIT:
        begin
            add_t <= 15'd0;
            if(cnt == 12'd1000)
            begin
                cnt <= 12'd0;
                if(num == 8'd250)
                    state <= BODY;
                else
                    state <= ONCE;
            end
            else
                cnt <= cnt + 1'b1;
        end
        default:
        begin
            state <= IDLE;
        end
    endcase
    end
end


endmodule
